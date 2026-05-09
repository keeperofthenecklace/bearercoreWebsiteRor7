Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get "technical-overview", to: "pages#technical_overview"

  get "docs",                       to: "docs#index"
  get "docs/corridor-ops",          to: "docs#corridor_ops"
  get "docs/issuance",              to: "docs#issuance"
  get "docs/validation-desk",       to: "docs#validation_desk"
  get "docs/deposit-burn",          to: "docs#deposit_burn"
  get "docs/governance",            to: "docs#governance"
  get "docs/audit-report",          to: "docs#audit_report"
  get "docs/system-events",         to: "docs#system_events"
  get "docs/interface-standards",   to: "docs#interface_standards"
end
