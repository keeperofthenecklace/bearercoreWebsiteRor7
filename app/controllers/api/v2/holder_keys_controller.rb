module Api
  module V2
    class HolderKeysController < ApplicationController
      skip_before_action :verify_authenticity_token

      STUB_HOLDER_KEYS = [
        { id: 1, holder_id: "HOLDER-NGA-FIRSTBANK-001",  institution_name: "First Bank of Nigeria",    swift_code: "FBNINGLA", country_code: "NGA", public_key: "ed25519:FBN001PUBKEY" },
        { id: 2, holder_id: "HOLDER-NGA-GTB-001",        institution_name: "Guaranty Trust Bank",      swift_code: "GTBINGLA", country_code: "NGA", public_key: "ed25519:GTB001PUBKEY" },
        { id: 3, holder_id: "HOLDER-NGA-ZENITH-001",     institution_name: "Zenith Bank",              swift_code: "ZEIBNGLA", country_code: "NGA", public_key: "ed25519:ZEN001PUBKEY" },
        { id: 4, holder_id: "HOLDER-GHA-GCB-001",        institution_name: "GCB Bank",                 swift_code: "GHCBGHAC", country_code: "GHA", public_key: "ed25519:GCB001PUBKEY" },
        { id: 5, holder_id: "HOLDER-GHA-ABSA-001",       institution_name: "Absa Bank Ghana",          swift_code: "BARCGHAC", country_code: "GHA", public_key: "ed25519:ABSA001PUBKEY" },
        { id: 6, holder_id: "HOLDER-GHA-ECOBANK-001",    institution_name: "Ecobank Ghana",            swift_code: "ECOCGHAC", country_code: "GHA", public_key: "ed25519:ECO_GHA001PUBKEY" },
        { id: 7, holder_id: "HOLDER-KEN-EQUITY-001",     institution_name: "Equity Bank Kenya",        swift_code: "EQBLKENA", country_code: "KEN", public_key: "ed25519:EQB_KEN001PUBKEY" },
        { id: 8, holder_id: "HOLDER-KEN-KCB-001",        institution_name: "KCB Bank Kenya",           swift_code: "KCBLKENX", country_code: "KEN", public_key: "ed25519:KCB001PUBKEY" },
        { id: 9, holder_id: "HOLDER-ZAF-STANDARD-001",   institution_name: "Standard Bank South Africa", swift_code: "SBZAZAJJ", country_code: "ZAF", public_key: "ed25519:SBZ001PUBKEY" },
        { id: 10, holder_id: "HOLDER-ZAF-FNB-001",       institution_name: "First National Bank",      swift_code: "FIRNZAJJ", country_code: "ZAF", public_key: "ed25519:FNB001PUBKEY" },
      ].freeze

      def index
        render json: STUB_HOLDER_KEYS
      end
    end
  end
end
