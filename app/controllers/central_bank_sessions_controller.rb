require "net/http"
require "uri"
require "json"

# Institutional web-portal login (hybrid). bearerCORE serves the UI, but
# OperatorAccount identity lives in SmartcheqWebsiteRor7. This controller bridges
# the login: it POSTs username + password + institution_swift to the SmartcheqWebsiteRor7
# auth endpoint and, on success, binds the returned institution profile + Doorkeeper
# token into the bearerCORE web session. The token is replayed by the Trade Claim
# modal so the SmartcheqWebsiteRor7 ABAC guard enforces origin scoping.
class CentralBankSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: []

  def new
    redirect_to portal_path if central_bank_authenticated?
  end

  def create
    username = params[:username].to_s.downcase.strip
    swift    = params[:institution_swift].to_s.strip.upcase
    password = params[:password].to_s

    if username.blank? || password.blank? || swift.blank?
      flash.now[:alert] = "Username, password and institutional SWIFT are all required."
      return render :new, status: :unprocessable_entity
    end

    result = authenticate_via_smartcheq(username, password, swift)

    if result.is_a?(Hash) && result["success"]
      data = result["data"] || {}
      session[:central_bank_authenticated] = true
      session[:operator_id]       = data["operator_id"]
      session[:institution_swift] = data["institution_swift"]
      session[:country_code]      = data["country_code"]
      session[:institution_name]  = data["institution_name"]
      session[:access_token]      = data["access_token"]

      return_to = session.delete(:central_bank_return_to) || portal_path
      redirect_to return_to, notice: "Secure session established for #{data["institution_swift"]}."
    else
      flash.now[:alert] = (result.is_a?(Hash) && result["error"].presence) ||
        "Invalid credentials, or the identity service is unavailable. Contact the protocol team."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Secure session ended."
  end

  private

  # Base URL of the SmartcheqWebsiteRor7 API (identity authority). Configure via
  # SMARTCHEQ_API_BASE (e.g. https://api.smartcheq.com); dev default assumes the
  # API runs on port 3001 alongside bearerCORE on 3000.
  def smartcheq_api_base
    ENV["SMARTCHEQ_API_BASE"].presence || "http://127.0.0.1:3001"
  end

  def authenticate_via_smartcheq(username, password, swift)
    uri  = URI.join(smartcheq_api_base.chomp("/") + "/",
                    "api/v2/central_bank_access/authenticate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 10

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req["Accept"]       = "application/json"
    req.body = { username: username, password: password, institution_swift: swift }.to_json

    res = http.request(req)
    JSON.parse(res.body)
  rescue => e
    Rails.logger.error("[central_bank_sessions] auth bridge failed: #{e.class}: #{e.message}")
    nil
  end
end
