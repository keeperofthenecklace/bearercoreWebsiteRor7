module Api
  module V2
    class CommercialBanksController < ApplicationController
      skip_before_action :verify_authenticity_token

      STUB_BANKS = {
        "NGA" => [
          { id: 101, name: "First Bank of Nigeria",         swift_code: "FBNINGLA", country_code: "NGA" },
          { id: 102, name: "Guaranty Trust Bank",           swift_code: "GTBINGLA", country_code: "NGA" },
          { id: 103, name: "Zenith Bank",                   swift_code: "ZEIBNGLA", country_code: "NGA" },
          { id: 104, name: "Access Bank Nigeria",           swift_code: "ABNGNGLA", country_code: "NGA" },
          { id: 105, name: "United Bank for Africa",        swift_code: "UNAFNGLA", country_code: "NGA" },
          { id: 106, name: "Fidelity Bank Nigeria",         swift_code: "FIDTNGLA", country_code: "NGA" },
          { id: 107, name: "Union Bank of Nigeria",         swift_code: "UBNINGLA", country_code: "NGA" },
          { id: 108, name: "Stanbic IBTC Bank",             swift_code: "SBICNGLA", country_code: "NGA" },
          { id: 109, name: "FCMB",                          swift_code: "FCMBNGLA", country_code: "NGA" },
          { id: 110, name: "Wema Bank",                     swift_code: "WEMANGLA", country_code: "NGA" },
          { id: 111, name: "Sterling Bank",                 swift_code: "NAIBNGLE", country_code: "NGA" },
          { id: 112, name: "Polaris Bank",                  swift_code: "TEEMNGLA", country_code: "NGA" },
        ],
        "GHA" => [
          { id: 201, name: "GCB Bank",                      swift_code: "GHCBGHAC", country_code: "GHA" },
          { id: 202, name: "Absa Bank Ghana",               swift_code: "BARCGHAC", country_code: "GHA" },
          { id: 203, name: "Ecobank Ghana",                 swift_code: "ECOCGHAC", country_code: "GHA" },
          { id: 204, name: "Standard Chartered Bank Ghana", swift_code: "SCBLGHAC", country_code: "GHA" },
          { id: 205, name: "Zenith Bank Ghana",             swift_code: "ZEIBGHAC", country_code: "GHA" },
          { id: 206, name: "Stanbic Bank Ghana",            swift_code: "SBICGHAC", country_code: "GHA" },
          { id: 207, name: "Fidelity Bank Ghana",           swift_code: "FBLIGHAC", country_code: "GHA" },
          { id: 208, name: "Access Bank Ghana",             swift_code: "ABNGGHAC", country_code: "GHA" },
          { id: 209, name: "CalBank",                       swift_code: "CABLGHAC", country_code: "GHA" },
          { id: 210, name: "United Bank for Africa Ghana",  swift_code: "UNAFGHAC", country_code: "GHA" },
          { id: 211, name: "Société Générale Ghana",        swift_code: "SOGEGHAC", country_code: "GHA" },
          { id: 212, name: "First Atlantic Bank",           swift_code: "FABLGHAC", country_code: "GHA" },
          { id: 213, name: "Republic Bank Ghana",           swift_code: "HFBLGHAC", country_code: "GHA" },
          { id: 214, name: "Prudential Bank Ghana",         swift_code: "PRBLGHAC", country_code: "GHA" },
          { id: 215, name: "Agricultural Development Bank", swift_code: "ADBKGHAC", country_code: "GHA" },
          { id: 216, name: "National Investment Bank",      swift_code: "NIBKGHAC", country_code: "GHA" },
        ],
        "SEN" => [
          { id: 301, name: "Banque de l'Habitat du Sénégal",   swift_code: "BHSESNDA", country_code: "SEN" },
          { id: 302, name: "Ecobank Sénégal",                   swift_code: "ECOCSNDA", country_code: "SEN" },
          { id: 303, name: "CBAO Groupe Attijariwafa",          swift_code: "CBAOSNDA", country_code: "SEN" },
          { id: 304, name: "Société Générale Sénégal",          swift_code: "SOGESNDA", country_code: "SEN" },
          { id: 305, name: "Banque Islamique du Sénégal",       swift_code: "BSSGSNDA", country_code: "SEN" },
          { id: 306, name: "United Bank for Africa Sénégal",    swift_code: "UNAFSNDA", country_code: "SEN" },
          { id: 307, name: "Banque Atlantique Sénégal",         swift_code: "ATLBSNDA", country_code: "SEN" },
          { id: 308, name: "Coris Bank Sénégal",                swift_code: "COBISNDA", country_code: "SEN" },
        ],
        "CIV" => [
          { id: 401, name: "Société Générale Côte d'Ivoire",    swift_code: "SOGECIAB", country_code: "CIV" },
          { id: 402, name: "Ecobank Côte d'Ivoire",             swift_code: "ECOCCIAB", country_code: "CIV" },
          { id: 403, name: "BICICI",                             swift_code: "BICICIAB", country_code: "CIV" },
          { id: 404, name: "Banque Atlantique Côte d'Ivoire",   swift_code: "ATLBCIAB", country_code: "CIV" },
          { id: 405, name: "Coris Bank Côte d'Ivoire",          swift_code: "COBICIAB", country_code: "CIV" },
          { id: 406, name: "United Bank for Africa Côte d'Ivoire", swift_code: "UNAFCIAB", country_code: "CIV" },
          { id: 407, name: "Banque Nationale d'Investissement",  swift_code: "BNIICIAB", country_code: "CIV" },
          { id: 408, name: "Standard Chartered Côte d'Ivoire",   swift_code: "SCBLCIAB", country_code: "CIV" },
        ],
        "BFA" => [
          { id: 501, name: "Coris Bank International",           swift_code: "COBIBFBF", country_code: "BFA" },
          { id: 502, name: "Ecobank Burkina",                    swift_code: "ECOCBFBF", country_code: "BFA" },
          { id: 503, name: "Société Générale Burkina Faso",      swift_code: "SOGEBFBF", country_code: "BFA" },
          { id: 504, name: "United Bank for Africa Burkina",     swift_code: "UNAFBFBF", country_code: "BFA" },
          { id: 505, name: "Banque Atlantique Burkina Faso",     swift_code: "ATLBBFBF", country_code: "BFA" },
          { id: 506, name: "Bank of Africa Burkina Faso",        swift_code: "AFRIBFBF", country_code: "BFA" },
        ],
        "MLI" => [
          { id: 601, name: "Banque de Développement du Mali",   swift_code: "BDMAMLBA", country_code: "MLI" },
          { id: 602, name: "Ecobank Mali",                      swift_code: "ECOCMLBA", country_code: "MLI" },
          { id: 603, name: "Société Générale Mali",             swift_code: "SOGEMLBA", country_code: "MLI" },
          { id: 604, name: "Bank of Africa Mali",               swift_code: "AFRIMLBA", country_code: "MLI" },
          { id: 605, name: "Banque Atlantique Mali",            swift_code: "ATLBMLBA", country_code: "MLI" },
          { id: 606, name: "Coris Bank Mali",                   swift_code: "COBIMLBA", country_code: "MLI" },
        ],
        "NER" => [
          { id: 701, name: "Banque Atlantique Niger",            swift_code: "ATLANENE", country_code: "NER" },
          { id: 702, name: "Ecobank Niger",                      swift_code: "ECOCNENE", country_code: "NER" },
          { id: 703, name: "Société Nigérienne de Banque",       swift_code: "SNIBNENE", country_code: "NER" },
          { id: 704, name: "Bank of Africa Niger",               swift_code: "AFRINENE", country_code: "NER" },
          { id: 705, name: "Coris Bank Niger",                   swift_code: "COBINENE", country_code: "NER" },
        ],
        "KEN" => [
          { id: 801, name: "Equity Bank Kenya",                  swift_code: "EQBLKENA", country_code: "KEN" },
          { id: 802, name: "KCB Bank Kenya",                     swift_code: "KCBLKENX", country_code: "KEN" },
          { id: 803, name: "Cooperative Bank Kenya",             swift_code: "CBAFKENA", country_code: "KEN" },
          { id: 804, name: "Standard Chartered Kenya",           swift_code: "SCBLKENX", country_code: "KEN" },
          { id: 805, name: "Absa Bank Kenya",                    swift_code: "BARCKENX", country_code: "KEN" },
          { id: 806, name: "Stanbic Bank Kenya",                 swift_code: "SBICKENX", country_code: "KEN" },
          { id: 807, name: "NCBA Bank Kenya",                    swift_code: "CBAFKENA", country_code: "KEN" },
          { id: 808, name: "I&M Bank Kenya",                     swift_code: "IMBLKENA", country_code: "KEN" },
          { id: 809, name: "Diamond Trust Bank Kenya",           swift_code: "DTKEKENA", country_code: "KEN" },
          { id: 810, name: "Family Bank Kenya",                  swift_code: "FABLKENA", country_code: "KEN" },
        ],
        "UGA" => [
          { id: 901, name: "Stanbic Bank Uganda",                swift_code: "SBICUGKA", country_code: "UGA" },
          { id: 902, name: "Equity Bank Uganda",                 swift_code: "EQBLUGKA", country_code: "UGA" },
          { id: 903, name: "Absa Bank Uganda",                   swift_code: "BARCUGKA", country_code: "UGA" },
          { id: 904, name: "Centenary Bank Uganda",              swift_code: "CENBUGKA", country_code: "UGA" },
          { id: 905, name: "dfcu Bank Uganda",                   swift_code: "DFCUUGKA", country_code: "UGA" },
          { id: 906, name: "Standard Chartered Uganda",          swift_code: "SCBLUGKA", country_code: "UGA" },
          { id: 907, name: "Housing Finance Bank Uganda",        swift_code: "HFBUUGKA", country_code: "UGA" },
        ],
        "TZA" => [
          { id: 1001, name: "CRDB Bank",                         swift_code: "CORUTZTZ", country_code: "TZA" },
          { id: 1002, name: "NMB Bank Tanzania",                 swift_code: "NMIBTZTZ", country_code: "TZA" },
          { id: 1003, name: "Standard Chartered Tanzania",       swift_code: "SCBLTZTZ", country_code: "TZA" },
          { id: 1004, name: "Stanbic Bank Tanzania",             swift_code: "SBICTZTZ", country_code: "TZA" },
          { id: 1005, name: "Absa Bank Tanzania",                swift_code: "BARCTZTZ", country_code: "TZA" },
          { id: 1006, name: "Equity Bank Tanzania",              swift_code: "EQBLTZTZ", country_code: "TZA" },
          { id: 1007, name: "KCB Bank Tanzania",                 swift_code: "KCBLTZTZ", country_code: "TZA" },
          { id: 1008, name: "NBC Bank Tanzania",                 swift_code: "NLCBTZTZ", country_code: "TZA" },
        ],
        "RWA" => [
          { id: 1101, name: "Bank of Kigali",                    swift_code: "BKIGRWRW", country_code: "RWA" },
          { id: 1102, name: "I&M Bank Rwanda",                   swift_code: "IMRWRWRW", country_code: "RWA" },
          { id: 1103, name: "Equity Bank Rwanda",                swift_code: "EQBLRWRW", country_code: "RWA" },
          { id: 1104, name: "KCB Bank Rwanda",                   swift_code: "KCBLRWRW", country_code: "RWA" },
          { id: 1105, name: "Ecobank Rwanda",                    swift_code: "ECOCRWRW", country_code: "RWA" },
          { id: 1106, name: "Cogebanque Rwanda",                 swift_code: "COGERWRW", country_code: "RWA" },
        ],
        "ZAF" => [
          { id: 1201, name: "Standard Bank South Africa",        swift_code: "SBZAZAJJ", country_code: "ZAF" },
          { id: 1202, name: "First National Bank",               swift_code: "FIRNZAJJ", country_code: "ZAF" },
          { id: 1203, name: "Nedbank",                           swift_code: "NEDSZAJJ", country_code: "ZAF" },
          { id: 1204, name: "Absa Bank South Africa",            swift_code: "ABSAZAJJ", country_code: "ZAF" },
          { id: 1205, name: "Investec Bank",                     swift_code: "INVEZAJJ", country_code: "ZAF" },
          { id: 1206, name: "Capitec Bank",                      swift_code: "CABLZAJJ", country_code: "ZAF" },
          { id: 1207, name: "Bidvest Bank",                      swift_code: "BIDBZAJJ", country_code: "ZAF" },
          { id: 1208, name: "Discovery Bank",                    swift_code: "DISCZA11", country_code: "ZAF" },
        ],
        "ZMB" => [
          { id: 1301, name: "Zanaco",                            swift_code: "ZNCOZMLU", country_code: "ZMB" },
          { id: 1302, name: "Stanbic Bank Zambia",               swift_code: "SBICZMLX", country_code: "ZMB" },
          { id: 1303, name: "Absa Bank Zambia",                  swift_code: "BARCZMLU", country_code: "ZMB" },
          { id: 1304, name: "First National Bank Zambia",        swift_code: "FIRNZMLU", country_code: "ZMB" },
          { id: 1305, name: "Equity Bank Zambia",                swift_code: "EQBLZMLU", country_code: "ZMB" },
          { id: 1306, name: "Atlas Mara Bank Zambia",            swift_code: "BKCHZMLU", country_code: "ZMB" },
        ],
        "MWI" => [
          { id: 1401, name: "National Bank of Malawi",           swift_code: "NBMAMWMW", country_code: "MWI" },
          { id: 1402, name: "Standard Bank Malawi",              swift_code: "SBICMWMX", country_code: "MWI" },
          { id: 1403, name: "First Merchant Bank Malawi",        swift_code: "FMBKMWMW", country_code: "MWI" },
          { id: 1404, name: "FDH Bank Malawi",                   swift_code: "FDHBMWMW", country_code: "MWI" },
          { id: 1405, name: "Ecobank Malawi",                    swift_code: "ECOCMWMW", country_code: "MWI" },
        ],
        "MOZ" => [
          { id: 1501, name: "BCI Fomento",                       swift_code: "BCIFMZMX", country_code: "MOZ" },
          { id: 1502, name: "Millennium BIM",                    swift_code: "MIBMMZMX", country_code: "MOZ" },
          { id: 1503, name: "Absa Bank Moçambique",              swift_code: "BARCMZMX", country_code: "MOZ" },
          { id: 1504, name: "Standard Bank Mozambique",          swift_code: "SBICMZMX", country_code: "MOZ" },
          { id: 1505, name: "First National Bank Mozambique",    swift_code: "FIRNMZMX", country_code: "MOZ" },
        ],
        "CMR" => [
          { id: 1601, name: "Afriland First Bank",               swift_code: "CCEICMCX", country_code: "CMR" },
          { id: 1602, name: "Ecobank Cameroun",                  swift_code: "ECOCCMCX", country_code: "CMR" },
          { id: 1603, name: "Société Générale Cameroun",         swift_code: "SOGECMCX", country_code: "CMR" },
          { id: 1604, name: "United Bank for Africa Cameroun",   swift_code: "UNAFCMCX", country_code: "CMR" },
          { id: 1605, name: "Standard Chartered Cameroun",       swift_code: "SCBLCMCX", country_code: "CMR" },
          { id: 1606, name: "Banque Atlantique Cameroun",        swift_code: "ATLBCMCX", country_code: "CMR" },
        ],
        "COG" => [
          { id: 1701, name: "Banque Commerciale Internationale Congo", swift_code: "BCIACGCX", country_code: "COG" },
          { id: 1702, name: "Ecobank Congo",                           swift_code: "ECOCCGCX", country_code: "COG" },
          { id: 1703, name: "Société Générale Congo",                  swift_code: "SOGECGCX", country_code: "COG" },
          { id: 1704, name: "United Bank for Africa Congo",            swift_code: "UNAFCGCX", country_code: "COG" },
        ],
        "MAR" => [
          { id: 1801, name: "Attijariwafa Bank",                 swift_code: "BCMAMAMC", country_code: "MAR" },
          { id: 1802, name: "Banque Populaire du Maroc",         swift_code: "BPCEAMAMC", country_code: "MAR" },
          { id: 1803, name: "CIH Bank",                          swift_code: "CIHMMAMC", country_code: "MAR" },
          { id: 1804, name: "BMCE Bank of Africa",               swift_code: "BMCEMAMC", country_code: "MAR" },
          { id: 1805, name: "Société Générale Maroc",            swift_code: "SOGEMAMC", country_code: "MAR" },
          { id: 1806, name: "Crédit du Maroc",                   swift_code: "CREDMAMC", country_code: "MAR" },
          { id: 1807, name: "Crédit Agricole du Maroc",          swift_code: "CAMRMAMC", country_code: "MAR" },
          { id: 1808, name: "BMCI",                              swift_code: "BMCIMAMC", country_code: "MAR" },
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
