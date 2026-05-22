class AdminConsoleController < ApplicationController
  before_action :require_central_bank_access

  def license
    @licenses = SoftwareLicense.recent
    @active_count = SoftwareLicense.active_licenses.count
    @total_count  = SoftwareLicense.count
  end
end
