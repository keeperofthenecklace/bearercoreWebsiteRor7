Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => '/cable'

  root "pages#home"
  get  "portal",             to: "pages#portal"
  get  "issuance/desk",     to: redirect("/portal")
  get  "technical-overview", to: "pages#technical_overview"
  get  "sandbox",            to: "pages#sandbox"
  get  "litepaper",          to: "pages#litepaper"
  get  "protocol-desk",      to: "pages#protocol_desk"
  get  "privacy",            to: "pages#privacy"
  get  "terms",              to: "pages#terms"

  get    "central-bank-access", to: "central_bank_sessions#new",     as: :central_bank_login
  post   "central-bank-access", to: "central_bank_sessions#create",  as: :central_bank_session
  delete "central-bank-access", to: "central_bank_sessions#destroy", as: :central_bank_logout

  resources :briefing_requests, only: [:create]

  namespace :api do
    namespace :v1 do
      get  'operator/current_identity', to: 'operator#current_identity'
      post 'operator/store_identity',   to: 'operator#store_identity'
      get  'operator/identities',       to: 'operator#identities'
      post 'operator/register_node',    to: 'operator#register_node'
    end

    namespace :v2 do
      resources :corridors, only: [:index, :show] do
        member do
          get  :liquidity_position
          get  :fx_quotes
          post :halt
          post :unhalt
          post :clear_reconciliation
        end
        collection do
          get :reconciliation
        end
      end

      resources :countries, only: [:index] do
        collection do
          get :by_iso3166
        end
      end

      resources :commercial_banks, only: [:index]
      resources :holder_keys, only: [:index] do
        collection do
          get :resolve
        end
      end
      resources :documents,        only: [:index, :create]

      resources :trade_claims, only: [:index, :create] do
        member do
          post :approve
          post :reject
          post :re_evaluate
          post :request_clarification
          post :cancel
        end
        collection do
          post :draft
          get  :clearance
        end
      end

      # Inbound RTGS boundary — commercial bank pacs.009 settlement webhook.
      post "rtgs/inbound/pacs009", to: "rtgs_webhooks#receive_pacs009"
      # RTGS reserve-interface heartbeat (read-only) for the Qt6 gateway indicator.
      get  "rtgs/status",          to: "rtgs_status#show"

      namespace :governance do
        resources :proposals, only: [:index, :create] do
          member do
            post :vote
            post :recall
          end
        end
      end
    end
  end

  get   "admin-console/license",          to: "admin_console#license",         as: :admin_console_license
  get   "admin-console/licenses-data",    to: "admin_console#licenses_data",   as: :admin_console_licenses_data, defaults: { format: :json }
  get   "admin-console/banks-data",       to: "admin_console#banks_data",      as: :admin_console_banks_data,    defaults: { format: :json }
  patch "admin-console/licences/:id",     to: "admin_console#update_licence",  as: :admin_console_update_licence

  get  "download-client",      to: "downloads#client_auth",      as: :client_download
  post "download-client",      to: "downloads#process_download",  as: :process_client_download
  get  "download-client/file", to: "downloads#serve_file",        as: :serve_client_download

  get "docs",                       to: "docs#index"
  get "docs/corridor-ops",          to: "docs#corridor_ops"
  get "docs/issuance",              to: "docs#issuance"
  get "docs/validation-desk",       to: "docs#validation_desk"
  get "docs/deposit-burn",          to: "docs#deposit_burn"
  get "docs/governance",            to: "docs#governance"
  get "docs/audit-report",          to: "docs#audit_report"
  get "docs/system-events",         to: "docs#system_events"
  get "docs/interface-standards",   to: "docs#interface_standards"
  get "docs/trade-claim",           to: "docs#trade_claim"
  get "docs/supervisor-desk",       to: "docs#supervisor_desk"
  get "docs/governor-desk",         to: "docs#governor_desk"

  # /documents mirrors /docs — same controller, same auth, canonical URL for bearerCORE
  get "documents",                      to: "docs#index",               as: :documents
  get "documents/corridor-ops",         to: "docs#corridor_ops",        as: :documents_corridor_ops
  get "documents/issuance",             to: "docs#issuance",            as: :documents_issuance
  get "documents/validation-desk",      to: "docs#validation_desk",     as: :documents_validation_desk
  get "documents/deposit-burn",         to: "docs#deposit_burn",        as: :documents_deposit_burn
  get "documents/governance",           to: "docs#governance",          as: :documents_governance
  get "documents/audit-report",         to: "docs#audit_report",        as: :documents_audit_report
  get "documents/system-events",        to: "docs#system_events",       as: :documents_system_events
  get "documents/interface-standards",  to: "docs#interface_standards", as: :documents_interface_standards
end
