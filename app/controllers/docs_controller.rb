class DocsController < ApplicationController
  layout 'application'
  before_action :require_central_bank_access

  def index
  end

  def environments_security
  end

  def corridor_ops
  end

  def issuance
  end

  def validation_desk
  end

  def deposit_burn
  end

  def governance
  end

  def audit_report
  end

  def system_events
  end

  def interface_standards
  end

  def trade_claim
  end

  def supervisor_desk
  end

  def governor_desk
  end

  def regional_gateways
  end
end
