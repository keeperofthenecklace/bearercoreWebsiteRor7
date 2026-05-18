module Api
  module V2
    class CommercialBanksController < ApplicationController
      skip_before_action :verify_authenticity_token

      STUB_BANKS = {
        "NGA" => [
          { id: 101, name: "First Bank of Nigeria",    swift_code: "FBNINGLA", country_code: "NGA" },
          { id: 102, name: "Guaranty Trust Bank",      swift_code: "GTBINGLA", country_code: "NGA" },
          { id: 103, name: "Zenith Bank",              swift_code: "ZEIBNGLA", country_code: "NGA" },
          { id: 104, name: "Access Bank Nigeria",      swift_code: "ABNGNGLA", country_code: "NGA" },
        ],
        "GHA" => [
          { id: 201, name: "GCB Bank",                 swift_code: "GHCBGHAC", country_code: "GHA" },
          { id: 202, name: "Absa Bank Ghana",          swift_code: "BARCGHAC", country_code: "GHA" },
          { id: 203, name: "Ecobank Ghana",            swift_code: "ECOCGHAC", country_code: "GHA" },
        ],
        "SEN" => [
          { id: 301, name: "Banque de l'Habitat du Sénégal", swift_code: "BHSESNDA", country_code: "SEN" },
          { id: 302, name: "Ecobank Sénégal",               swift_code: "ECOCSNDA", country_code: "SEN" },
          { id: 303, name: "CBAO Groupe Attijariwafa",       swift_code: "CBAOSNDA", country_code: "SEN" },
        ],
        "CIV" => [
          { id: 401, name: "Société Générale Côte d'Ivoire", swift_code: "SOGECIAB", country_code: "CIV" },
          { id: 402, name: "Ecobank Côte d'Ivoire",          swift_code: "ECOCCIAB", country_code: "CIV" },
          { id: 403, name: "BICICI",                          swift_code: "BICICIAB", country_code: "CIV" },
        ],
        "BFA" => [
          { id: 501, name: "Coris Bank International", swift_code: "COBIBFBF", country_code: "BFA" },
          { id: 502, name: "Ecobank Burkina",          swift_code: "ECOCBFBF", country_code: "BFA" },
        ],
        "MLI" => [
          { id: 601, name: "Banque de Développement du Mali", swift_code: "BDMAMLBA", country_code: "MLI" },
          { id: 602, name: "Ecobank Mali",                    swift_code: "ECOCMLBA", country_code: "MLI" },
        ],
        "NER" => [
          { id: 701, name: "Banque Atlantique Niger", swift_code: "ATLANENE", country_code: "NER" },
          { id: 702, name: "Ecobank Niger",           swift_code: "ECOCNENE", country_code: "NER" },
        ],
        "KEN" => [
          { id: 801, name: "Equity Bank Kenya",       swift_code: "EQBLKENA", country_code: "KEN" },
          { id: 802, name: "KCB Bank Kenya",          swift_code: "KCBLKENX", country_code: "KEN" },
          { id: 803, name: "Cooperative Bank Kenya",  swift_code: "CBAFKENA", country_code: "KEN" },
        ],
        "UGA" => [
          { id: 901, name: "Stanbic Bank Uganda",     swift_code: "SBICUGKA", country_code: "UGA" },
          { id: 902, name: "Equity Bank Uganda",      swift_code: "EQBLUGKA", country_code: "UGA" },
        ],
        "TZA" => [
          { id: 1001, name: "CRDB Bank",              swift_code: "CORUTZTZ", country_code: "TZA" },
          { id: 1002, name: "NMB Bank Tanzania",      swift_code: "NMIBTZTZ", country_code: "TZA" },
        ],
        "RWA" => [
          { id: 1101, name: "Bank of Kigali",         swift_code: "BKIGRWRW", country_code: "RWA" },
          { id: 1102, name: "I&M Bank Rwanda",        swift_code: "IMRWRWRW", country_code: "RWA" },
        ],
        "ZAF" => [
          { id: 1201, name: "Standard Bank South Africa", swift_code: "SBZAZAJJ", country_code: "ZAF" },
          { id: 1202, name: "First National Bank",        swift_code: "FIRNZAJJ", country_code: "ZAF" },
          { id: 1203, name: "Nedbank",                    swift_code: "NEDSZAJJ", country_code: "ZAF" },
        ],
        "ZMB" => [
          { id: 1301, name: "Zanaco",                 swift_code: "ZNCOZMLU", country_code: "ZMB" },
          { id: 1302, name: "Stanbic Bank Zambia",    swift_code: "SBICZMLX", country_code: "ZMB" },
        ],
        "MWI" => [
          { id: 1401, name: "National Bank of Malawi", swift_code: "NBMAMWMW", country_code: "MWI" },
          { id: 1402, name: "Standard Bank Malawi",    swift_code: "SBICMWMX", country_code: "MWI" },
        ],
        "MOZ" => [
          { id: 1501, name: "BCI Fomento",             swift_code: "BCIFMZMX", country_code: "MOZ" },
          { id: 1502, name: "Millennium BIM",          swift_code: "MIBMMZMX", country_code: "MOZ" },
        ],
        "CMR" => [
          { id: 1601, name: "Afriland First Bank",     swift_code: "CCEICMCX", country_code: "CMR" },
          { id: 1602, name: "Ecobank Cameroun",        swift_code: "ECOCCMCX", country_code: "CMR" },
        ],
        "COG" => [
          { id: 1701, name: "Banque Commerciale Internationale Congo", swift_code: "BCIACGCX", country_code: "COG" },
          { id: 1702, name: "Ecobank Congo",                           swift_code: "ECOCCGCX", country_code: "COG" },
        ],
        "MAR" => [
          { id: 1801, name: "Attijariwafa Bank",       swift_code: "BCMAMAMC", country_code: "MAR" },
          { id: 1802, name: "Banque Populaire Maroc",  swift_code: "BPCEAMAMC", country_code: "MAR" },
          { id: 1803, name: "CIH Bank",                swift_code: "CIHMMAMC", country_code: "MAR" },
        ],
      }.freeze

      def index
        country_code = (params[:country_code] || '').upcase.strip
        country_id   = params[:country_id].to_s

        banks = if country_code.present?
          STUB_BANKS[country_code] || []
        elsif country_id.present?
          # Look up ISO code by matching country id (1=NGA, 2=GHA, etc.)
          iso = STUB_BANKS.keys.find { |k| Api::V2::CountriesController::STUB_COUNTRIES.find { |c| c[:id].to_s == country_id && (c[:code] == k || c[:alpha2] == k) } }
          iso ? STUB_BANKS[iso] : []
        else
          STUB_BANKS.values.flatten
        end

        render json: banks
      end
    end
  end
end
