class AdminConsoleController < ApplicationController
  before_action :require_central_bank_access

  def license
    @licenses = SoftwareLicense.recent
    @active_count = SoftwareLicense.active_licenses.count
    @total_count  = SoftwareLicense.count
  end

  def banks_data
    require "net/http"
    require "json"

    uri = URI("https://www.smartcheq.com/software_licences/banks_list.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 8

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      render json: response.body, content_type: "application/json"
    else
      render json: { banks: [], error: "upstream #{response.code}" }, status: :ok
    end
  rescue => e
    Rails.logger.warn "[AdminConsole#banks_data] SmartCHEQ fetch failed: #{e.message}"
    render json: { banks: [], error: e.message }, status: :ok
  end

  def update_licence
    require "net/http"
    require "json"

    id  = params[:id].to_i
    uri = URI("https://www.smartcheq.com/software_licences/#{id}/admin_update")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 8

    request = Net::HTTP::Patch.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"]       = "application/json"

    allowed = params.permit(:name, :email, :ip_address, :status, :active, :license_type, :duration, :central_bank_name)
    request.body = { software_license: allowed.to_h }.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      render json: response.body, content_type: "application/json"
    else
      render json: { success: false, error: "upstream #{response.code}" }, status: :ok
    end
  rescue => e
    Rails.logger.warn "[AdminConsole#update_licence] SmartCHEQ update failed: #{e.message}"
    render json: { success: false, error: e.message }, status: :ok
  end

  def licenses_data
    require "net/http"
    require "json"

    uri = URI("https://www.smartcheq.com/software_licences.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 8

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      render json: response.body, content_type: "application/json"
    else
      render json: { software_licenses: [], error: "upstream #{response.code}" }, status: :ok
    end
  rescue => e
    Rails.logger.warn "[AdminConsole#licenses_data] SmartCHEQ fetch failed: #{e.message}"
    render json: { software_licenses: [], error: e.message }, status: :ok
  end
end
