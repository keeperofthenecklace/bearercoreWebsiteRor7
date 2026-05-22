class AdminConsoleController < ApplicationController
  before_action :require_central_bank_access

  def license
    @licenses = SoftwareLicense.recent
    @active_count = SoftwareLicense.active_licenses.count
    @total_count  = SoftwareLicense.count
  end

  def licenses_data
    licenses = SoftwareLicense.order(created_at: :desc).map do |l|
      {
        id:           l.id,
        name:         l.name,
        email:        l.email,
        ip_address:   l.ip_address,
        status:       l.status,
        active:       l.active,
        duration:     l.duration&.strftime("%Y-%m-%d"),
        centralbank:  l.centralbank,
        swiftcode:    l.swiftcode,
        licenseid:    l.licenseid,
        license_type: l.license_type,
        uri:          l.uri,
        bankID:       l.bankID
      }
    end
    render json: { software_licenses: licenses }
  end
end
