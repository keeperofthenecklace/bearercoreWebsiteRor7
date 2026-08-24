# Dashboard RBAC helpers — gate operational card visibility by the operator role
# bound in session[:role] (plumbed from the SmartCHEQ auth bridge).
#
# Role map mirrors SmartCHEQ RbacPolicy::ROLE_SCOPES:
#   commercial → minting_officer, corridor_operator
#   regulator  → compliance_officer, forensic_auditor, governor, system_admin
module DashboardRolesHelper
  COMMERCIAL_ROLES = %w[minting_officer corridor_operator].freeze
  REGULATOR_ROLES  = %w[compliance_officer forensic_auditor governor system_admin].freeze

  def dashboard_role
    session[:role].to_s
  end

  def role_bound?
    dashboard_role.present?
  end

  def regulator_operator?
    REGULATOR_ROLES.include?(dashboard_role)
  end

  def commercial_operator?
    COMMERCIAL_ROLES.include?(dashboard_role)
  end

  # Supervisor Desk visibility. Regulators always see it. On the public /sandbox,
  # role-less visitors and commercial operators may also open it for testing —
  # flagged via supervisor_sandbox_sim? so the card carries a SANDBOX pill.
  def show_supervisor_card?
    regulator_operator? || !role_bound? || commercial_operator?
  end

  # Governor Desk stays regulator-only (no sandbox testing exception granted),
  # but role-less public demo visitors still see it.
  def show_governor_card?
    regulator_operator? || !role_bound?
  end

  # True when Supervisor Desk access is a sandbox simulation rather than a real
  # regulator entitlement — drives the [ SANDBOX SIMULATION ] pill.
  def supervisor_sandbox_sim?
    !regulator_operator?
  end
end
