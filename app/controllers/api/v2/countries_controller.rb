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
