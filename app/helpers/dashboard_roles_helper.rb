# Dashboard RBAC helpers — gate operational card visibility by the operator role
# bound in session[:role] (plumbed from the SmartCHEQ auth bridge).
#
# Role map mirrors SmartCHEQ RbacPolicy::ROLE_SCOPES:
#   CB node/platform → minting_officer, corridor_operator (commercial-node) +
#                      compliance_officer, forensic_auditor, governor, system_admin
#   dealer-bank maker → commercial_institution_operator (Trade Claim ONLY)
module DashboardRolesHelper
  COMMERCIAL_ROLES  = %w[minting_officer corridor_operator].freeze
  REGULATOR_ROLES   = %w[compliance_officer forensic_auditor governor system_admin].freeze
  # Dealer-bank claim maker — Trade Claim / Counterparty Portal only, zero sovereign.
  CLAIM_MAKER_ROLES = %w[commercial_institution_operator].freeze

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

  # Dealer-bank maker (Segregation of Duties enclosure): Trade Claim only.
  def claim_maker?
    CLAIM_MAKER_ROLES.include?(dashboard_role)
  end

  # Supervisor Desk visibility. Regulators always see it. On the public /sandbox,
  # role-less visitors and CB-node commercial operators may also open it for
  # testing — flagged via supervisor_sandbox_sim? so the card carries a SANDBOX
  # pill. A dealer-bank claim maker NEVER sees it (zero sovereign access).
  def show_supervisor_card?
    return false if claim_maker?
    regulator_operator? || !role_bound? || commercial_operator?
  end

  # Governor Desk stays regulator-only (role-less public demo visitors still see
  # it); a dealer-bank claim maker is hard-excluded.
  def show_governor_card?
    return false if claim_maker?
    regulator_operator? || !role_bound?
  end

  # True when Supervisor Desk access is a sandbox simulation rather than a real
  # regulator entitlement — drives the [ SANDBOX SIMULATION ] pill.
  def supervisor_sandbox_sim?
    !regulator_operator?
  end

  # Track Submissions (read-only Trade Claim Status Monitor). Shown to commercial
  # bank operators — the dealer-bank claim maker (its primary audience) and CB-node
  # commercial operators — so they can monitor their own institution's claims. The
  # backing endpoint is strictly own-institution scoped and requires an identified
  # operator, so it is not offered to role-less public/demo visitors.
  def show_track_submissions_card?
    claim_maker? || commercial_operator?
  end
end
