module Api
  module V2
    class CountriesController < ApplicationController
      skip_before_action :verify_authenticity_token

      STUB_COUNTRIES = [
        { id:  1, name: "Nigeria",            code: "NGA", iso_code: "NGA", alpha3: "NGA", alpha2: "NG", currency: "NGN", central_bank: "Central Bank of Nigeria",                          swift_code: "CBNENIGX" },
        { id:  2, name: "Ghana",              code: "GHA", iso_code: "GHA", alpha3: "GHA", alpha2: "GH", currency: "GHS", central_bank: "Bank of Ghana",                                    swift_code: "GHCBGHAC" },
        { id:  3, name: "Senegal",            code: "SEN", iso_code: "SEN", alpha3: "SEN", alpha2: "SN", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id:  4, name: "Côte d'Ivoire",      code: "CIV", iso_code: "CIV", alpha3: "CIV", alpha2: "CI", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id:  5, name: "Burkina Faso",       code: "BFA", iso_code: "BFA", alpha3: "BFA", alpha2: "BF", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id:  6, name: "Mali",               code: "MLI", iso_code: "MLI", alpha3: "MLI", alpha2: "ML", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id:  7, name: "Niger",              code: "NER", iso_code: "NER", alpha3: "NER", alpha2: "NE", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id:  8, name: "Kenya",              code: "KEN", iso_code: "KEN", alpha3: "KEN", alpha2: "KE", currency: "KES", central_bank: "Central Bank of Kenya",                            swift_code: "CBKEKEPA" },
        { id:  9, name: "Uganda",             code: "UGA", iso_code: "UGA", alpha3: "UGA", alpha2: "UG", currency: "UGX", central_bank: "Bank of Uganda",                                   swift_code: "BOUGUGKA" },
        { id: 10, name: "Tanzania",           code: "TZA", iso_code: "TZA", alpha3: "TZA", alpha2: "TZ", currency: "TZS", central_bank: "Bank of Tanzania",                                 swift_code: "BOTATZTZ" },
        { id: 11, name: "Rwanda",             code: "RWA", iso_code: "RWA", alpha3: "RWA", alpha2: "RW", currency: "RWF", central_bank: "National Bank of Rwanda",                          swift_code: "BNRWRWRW" },
        { id: 12, name: "South Africa",       code: "ZAF", iso_code: "ZAF", alpha3: "ZAF", alpha2: "ZA", currency: "ZAR", central_bank: "South African Reserve Bank",                       swift_code: "SARBZAJJ" },
        { id: 13, name: "Zambia",             code: "ZMB", iso_code: "ZMB", alpha3: "ZMB", alpha2: "ZM", currency: "ZMW", central_bank: "Bank of Zambia",                                   swift_code: "BOCZZMLU" },
        { id: 14, name: "Malawi",             code: "MWI", iso_code: "MWI", alpha3: "MWI", alpha2: "MW", currency: "MWK", central_bank: "Reserve Bank of Malawi",                           swift_code: "RESMWXXX" },
        { id: 15, name: "Mozambique",         code: "MOZ", iso_code: "MOZ", alpha3: "MOZ", alpha2: "MZ", currency: "MZN", central_bank: "Banco de Moçambique",                              swift_code: "BMMZMXXX" },
        { id: 16, name: "Cameroon",           code: "CMR", iso_code: "CMR", alpha3: "CMR", alpha2: "CM", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",           swift_code: "BEACCMCX" },
        { id: 17, name: "Republic of Congo",  code: "COG", iso_code: "COG", alpha3: "COG", alpha2: "CG", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",           swift_code: "BEACCGCX" },
        { id: 18, name: "Morocco",            code: "MAR", iso_code: "MAR", alpha3: "MAR", alpha2: "MA", currency: "MAD", central_bank: "Bank Al-Maghrib",                                  swift_code: "BKAMMXXX" },
        # ── Remaining AU member states (ids 19–54) ─────────────────────────────
        # ISO 3166 codes + ISO 4217 currencies + central-bank names are accurate.
        # BIC/SWIFT codes are best-effort — verify against a SWIFT directory
        # before non-sandbox use (WAEMU→BCEABRBI, CEMAC→BEAC* match existing rows).
        { id: 19, name: "Algeria",                    code: "DZA", iso_code: "DZA", alpha3: "DZA", alpha2: "DZ", currency: "DZD", central_bank: "Bank of Algeria",                                     swift_code: "BALGDZAL" },
        { id: 20, name: "Angola",                     code: "AGO", iso_code: "AGO", alpha3: "AGO", alpha2: "AO", currency: "AOA", central_bank: "Banco Nacional de Angola",                            swift_code: "BNANAOLU" },
        { id: 21, name: "Benin",                      code: "BEN", iso_code: "BEN", alpha3: "BEN", alpha2: "BJ", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id: 22, name: "Botswana",                   code: "BWA", iso_code: "BWA", alpha3: "BWA", alpha2: "BW", currency: "BWP", central_bank: "Bank of Botswana",                                    swift_code: "" },
        { id: 23, name: "Burundi",                    code: "BDI", iso_code: "BDI", alpha3: "BDI", alpha2: "BI", currency: "BIF", central_bank: "Banque de la République du Burundi",                  swift_code: "BRBUBIBI" },
        { id: 24, name: "Cape Verde",                 code: "CPV", iso_code: "CPV", alpha3: "CPV", alpha2: "CV", currency: "CVE", central_bank: "Banco de Cabo Verde",                                 swift_code: "" },
        { id: 25, name: "Central African Republic",   code: "CAF", iso_code: "CAF", alpha3: "CAF", alpha2: "CF", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",             swift_code: "BEACCFCX" },
        { id: 26, name: "Chad",                       code: "TCD", iso_code: "TCD", alpha3: "TCD", alpha2: "TD", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",             swift_code: "BEACTDCX" },
        { id: 27, name: "Comoros",                    code: "COM", iso_code: "COM", alpha3: "COM", alpha2: "KM", currency: "KMF", central_bank: "Banque Centrale des Comores",                        swift_code: "" },
        { id: 28, name: "DR Congo",                   code: "COD", iso_code: "COD", alpha3: "COD", alpha2: "CD", currency: "CDF", central_bank: "Banque Centrale du Congo",                           swift_code: "BCDCCDKI" },
        { id: 29, name: "Djibouti",                   code: "DJI", iso_code: "DJI", alpha3: "DJI", alpha2: "DJ", currency: "DJF", central_bank: "Banque Centrale de Djibouti",                        swift_code: "" },
        { id: 30, name: "Egypt",                      code: "EGY", iso_code: "EGY", alpha3: "EGY", alpha2: "EG", currency: "EGP", central_bank: "Central Bank of Egypt",                              swift_code: "CBEGEGCX" },
        { id: 31, name: "Equatorial Guinea",          code: "GNQ", iso_code: "GNQ", alpha3: "GNQ", alpha2: "GQ", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",             swift_code: "BEACGQGX" },
        { id: 32, name: "Eritrea",                    code: "ERI", iso_code: "ERI", alpha3: "ERI", alpha2: "ER", currency: "ERN", central_bank: "Bank of Eritrea",                                    swift_code: "" },
        { id: 33, name: "Eswatini",                   code: "SWZ", iso_code: "SWZ", alpha3: "SWZ", alpha2: "SZ", currency: "SZL", central_bank: "Central Bank of Eswatini",                           swift_code: "" },
        { id: 34, name: "Ethiopia",                   code: "ETH", iso_code: "ETH", alpha3: "ETH", alpha2: "ET", currency: "ETB", central_bank: "National Bank of Ethiopia",                         swift_code: "NBETETAA" },
        { id: 35, name: "Gabon",                      code: "GAB", iso_code: "GAB", alpha3: "GAB", alpha2: "GA", currency: "XAF", central_bank: "Banque des États de l'Afrique Centrale",             swift_code: "BEACGALX" },
        { id: 36, name: "Gambia",                     code: "GMB", iso_code: "GMB", alpha3: "GMB", alpha2: "GM", currency: "GMD", central_bank: "Central Bank of The Gambia",                         swift_code: "" },
        { id: 37, name: "Guinea",                     code: "GIN", iso_code: "GIN", alpha3: "GIN", alpha2: "GN", currency: "GNF", central_bank: "Banque Centrale de la République de Guinée",         swift_code: "BCRGGNGN" },
        { id: 38, name: "Guinea-Bissau",              code: "GNB", iso_code: "GNB", alpha3: "GNB", alpha2: "GW", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id: 39, name: "Lesotho",                    code: "LSO", iso_code: "LSO", alpha3: "LSO", alpha2: "LS", currency: "LSL", central_bank: "Central Bank of Lesotho",                            swift_code: "" },
        { id: 40, name: "Liberia",                    code: "LBR", iso_code: "LBR", alpha3: "LBR", alpha2: "LR", currency: "LRD", central_bank: "Central Bank of Liberia",                            swift_code: "CBLILRLM" },
        { id: 41, name: "Libya",                      code: "LBY", iso_code: "LBY", alpha3: "LBY", alpha2: "LY", currency: "LYD", central_bank: "Central Bank of Libya",                              swift_code: "CBLYLYLX" },
        { id: 42, name: "Madagascar",                 code: "MDG", iso_code: "MDG", alpha3: "MDG", alpha2: "MG", currency: "MGA", central_bank: "Banky Foiben'i Madagasikara",                        swift_code: "" },
        { id: 43, name: "Mauritania",                 code: "MRT", iso_code: "MRT", alpha3: "MRT", alpha2: "MR", currency: "MRU", central_bank: "Banque Centrale de Mauritanie",                      swift_code: "BCMRMRMR" },
        { id: 44, name: "Mauritius",                  code: "MUS", iso_code: "MUS", alpha3: "MUS", alpha2: "MU", currency: "MUR", central_bank: "Bank of Mauritius",                                  swift_code: "BOMAMUMU" },
        { id: 45, name: "Namibia",                    code: "NAM", iso_code: "NAM", alpha3: "NAM", alpha2: "NA", currency: "NAD", central_bank: "Bank of Namibia",                                    swift_code: "" },
        { id: 46, name: "São Tomé and Príncipe",      code: "STP", iso_code: "STP", alpha3: "STP", alpha2: "ST", currency: "STN", central_bank: "Banco Central de São Tomé e Príncipe",              swift_code: "BCSTSTST" },
        { id: 47, name: "Seychelles",                 code: "SYC", iso_code: "SYC", alpha3: "SYC", alpha2: "SC", currency: "SCR", central_bank: "Central Bank of Seychelles",                         swift_code: "" },
        { id: 48, name: "Sierra Leone",               code: "SLE", iso_code: "SLE", alpha3: "SLE", alpha2: "SL", currency: "SLE", central_bank: "Bank of Sierra Leone",                              swift_code: "" },
        { id: 49, name: "Somalia",                    code: "SOM", iso_code: "SOM", alpha3: "SOM", alpha2: "SO", currency: "SOS", central_bank: "Central Bank of Somalia",                           swift_code: "" },
        { id: 50, name: "South Sudan",                code: "SSD", iso_code: "SSD", alpha3: "SSD", alpha2: "SS", currency: "SSP", central_bank: "Bank of South Sudan",                               swift_code: "" },
        { id: 51, name: "Sudan",                      code: "SDN", iso_code: "SDN", alpha3: "SDN", alpha2: "SD", currency: "SDG", central_bank: "Central Bank of Sudan",                              swift_code: "" },
        { id: 52, name: "Togo",                       code: "TGO", iso_code: "TGO", alpha3: "TGO", alpha2: "TG", currency: "XOF", central_bank: "Banque Centrale des États de l'Afrique de l'Ouest", swift_code: "BCEABRBI" },
        { id: 53, name: "Tunisia",                    code: "TUN", iso_code: "TUN", alpha3: "TUN", alpha2: "TN", currency: "TND", central_bank: "Central Bank of Tunisia",                            swift_code: "BCTNTNTT" },
        { id: 54, name: "Zimbabwe",                   code: "ZWE", iso_code: "ZWE", alpha3: "ZWE", alpha2: "ZW", currency: "ZWG", central_bank: "Reserve Bank of Zimbabwe",                           swift_code: "" },
      ].freeze

      def index
        render json: STUB_COUNTRIES
      end

      def by_iso3166
        code = (params[:code] || '').upcase.strip
        country = STUB_COUNTRIES.find { |c| c[:code] == code || c[:alpha2] == code || c[:alpha3] == code }
        if country
          render json: {
            id:                   country[:id],
            name:                 country[:name],
            code:                 country[:code],
            alpha2:               country[:alpha2],
            alpha3:               country[:alpha3],
            currency:             country[:currency],
            central_bank:         country[:central_bank],
            central_bank_swifts:  [country[:swift_code]],
            swift_code:           country[:swift_code],
          }
        else
          render json: { error: "Country not found for code: #{code}" }, status: :not_found
        end
      end
    end
  end
end
