class AdminConsoleController < ApplicationController
  before_action :require_central_bank_access

  def license
    @licenses = SoftwareLicense.recent
    @active_count = SoftwareLicense.active_licenses.count
    @total_count  = SoftwareLicense.count
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
