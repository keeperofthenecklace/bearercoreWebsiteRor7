Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get  "portal",             to: "pages#portal"
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
    namespace :v2 do
      resources :corridors, only: [:index, :show] do
        member do
          get  :liquidity_position
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
      resources :holder_keys,      only: [:index]
      resources :documents,        only: [:index, :create]

      resources :trade_claims, only: [:index, :create] do
        collection do
          post :draft
        end
      end

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
