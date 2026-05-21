class DownloadsController < ApplicationController
  before_action :require_central_bank_access

  def client_auth
  end

  def process_download
    unless params[:eula_agreed] == "1"
      flash[:error] = "You must agree to the End-User License Agreement to download."
      redirect_to client_download_path and return
    end

    session[:bearercore_download_authorized] = true
    redirect_to serve_client_download_path
  end

  def serve_file
    unless session[:bearercore_download_authorized]
      flash[:error] = "Please agree to the EULA first."
      redirect_to client_download_path and return
    end

    session[:bearercore_download_authorized] = nil
    file_path = Rails.root.join("public", "downloads", "SmartCheq.dmg")

    if File.exist?(file_path)
      send_file file_path,
                filename: "bearerCORE-Desktop.dmg",
                type: "application/x-apple-diskimage",
                disposition: "attachment"
    else
      flash[:error] = "Download file unavailable. Contact support."
      redirect_to client_download_path
    end
  end
end
