module Api
  module V2
    class HolderKeysController < ApplicationController
      skip_before_action :verify_authenticity_token

      STUB_HOLDER_KEYS = [
        # ── NGA ───────────────────────────────────────────────────────────────
        { id:   1, holder_id: "HOLDER-NGA-FBNINGLA-001", institution_name: "First Bank of Nigeria",         swift_code: "FBNINGLA", country_code: "NGA", public_key: "ed25519:FBN001PUBKEY" },
        { id:   2, holder_id: "HOLDER-NGA-GTBINGLA-001", institution_name: "Guaranty Trust Bank",           swift_code: "GTBINGLA", country_code: "NGA", public_key: "ed25519:GTB001PUBKEY" },
        { id:   3, holder_id: "HOLDER-NGA-ZEIBNGLA-001", institution_name: "Zenith Bank",                   swift_code: "ZEIBNGLA", country_code: "NGA", public_key: "ed25519:ZEN001PUBKEY" },
        { id:   4, holder_id: "HOLDER-NGA-ABNGNGLA-001", institution_name: "Access Bank Nigeria",           swift_code: "ABNGNGLA", country_code: "NGA", public_key: "ed25519:ABN_NGA001PUBKEY" },
        { id:   5, holder_id: "HOLDER-NGA-UNAFNGLA-001", institution_name: "United Bank for Africa",        swift_code: "UNAFNGLA", country_code: "NGA", public_key: "ed25519:UBA_NGA001PUBKEY" },
        { id:   6, holder_id: "HOLDER-NGA-FIDTNGLA-001", institution_name: "Fidelity Bank Nigeria",         swift_code: "FIDTNGLA", country_code: "NGA", public_key: "ed25519:FID_NGA001PUBKEY" },
        { id:   7, holder_id: "HOLDER-NGA-UBNINGLA-001", institution_name: "Union Bank of Nigeria",         swift_code: "UBNINGLA", country_code: "NGA", public_key: "ed25519:UBN001PUBKEY" },
        { id:   8, holder_id: "HOLDER-NGA-SBICNGLA-001", institution_name: "Stanbic IBTC Bank",             swift_code: "SBICNGLA", country_code: "NGA", public_key: "ed25519:SBI_NGA001PUBKEY" },
        { id:   9, holder_id: "HOLDER-NGA-FCMBNGLA-001", institution_name: "FCMB",                          swift_code: "FCMBNGLA", country_code: "NGA", public_key: "ed25519:FCM001PUBKEY" },
        { id:  10, holder_id: "HOLDER-NGA-WEMANGLA-001", institution_name: "Wema Bank",                     swift_code: "WEMANGLA", country_code: "NGA", public_key: "ed25519:WEM001PUBKEY" },
        { id:  11, holder_id: "HOLDER-NGA-NAIBNGLE-001", institution_name: "Sterling Bank",                 swift_code: "NAIBNGLE", country_code: "NGA", public_key: "ed25519:STR_NGA001PUBKEY" },
        { id:  12, holder_id: "HOLDER-NGA-TEEMNGLA-001", institution_name: "Polaris Bank",                  swift_code: "TEEMNGLA", country_code: "NGA", public_key: "ed25519:POL001PUBKEY" },

        # ── GHA ───────────────────────────────────────────────────────────────
        { id:  13, holder_id: "HOLDER-GHA-GHCBGHAC-001", institution_name: "GCB Bank",                      swift_code: "GHCBGHAC", country_code: "GHA", public_key: "ed25519:GCB001PUBKEY" },
        { id:  14, holder_id: "HOLDER-GHA-BARCGHAC-001", institution_name: "Absa Bank Ghana",               swift_code: "BARCGHAC", country_code: "GHA", public_key: "ed25519:ABS_GHA001PUBKEY" },
        { id:  15, holder_id: "HOLDER-GHA-ECOCGHAC-001", institution_name: "Ecobank Ghana",                 swift_code: "ECOCGHAC", country_code: "GHA", public_key: "ed25519:ECO_GHA001PUBKEY" },
        { id:  16, holder_id: "HOLDER-GHA-SCBLGHAC-001", institution_name: "Standard Chartered Bank Ghana", swift_code: "SCBLGHAC", country_code: "GHA", public_key: "ed25519:SCB_GHA001PUBKEY" },
        { id:  17, holder_id: "HOLDER-GHA-ZEIBGHAC-001", institution_name: "Zenith Bank Ghana",             swift_code: "ZEIBGHAC", country_code: "GHA", public_key: "ed25519:ZEN_GHA001PUBKEY" },
        { id:  18, holder_id: "HOLDER-GHA-SBICGHAC-001", institution_name: "Stanbic Bank Ghana",            swift_code: "SBICGHAC", country_code: "GHA", public_key: "ed25519:SBI_GHA001PUBKEY" },
        { id:  19, holder_id: "HOLDER-GHA-FBLIGHAC-001", institution_name: "Fidelity Bank Ghana",           swift_code: "FBLIGHAC", country_code: "GHA", public_key: "ed25519:FID_GHA001PUBKEY" },
        { id:  20, holder_id: "HOLDER-GHA-ABNGGHAC-001", institution_name: "Access Bank Ghana",             swift_code: "ABNGGHAC", country_code: "GHA", public_key: "ed25519:ABN_GHA001PUBKEY" },
        { id:  21, holder_id: "HOLDER-GHA-CABLGHAC-001", institution_name: "CalBank",                       swift_code: "CABLGHAC", country_code: "GHA", public_key: "ed25519:CAL001PUBKEY" },
        { id:  22, holder_id: "HOLDER-GHA-UNAFGHAC-001", institution_name: "United Bank for Africa Ghana",  swift_code: "UNAFGHAC", country_code: "GHA", public_key: "ed25519:UBA_GHA001PUBKEY" },
        { id:  23, holder_id: "HOLDER-GHA-SOGEGHAC-001", institution_name: "Société Générale Ghana",        swift_code: "SOGEGHAC", country_code: "GHA", public_key: "ed25519:SOG_GHA001PUBKEY" },
        { id:  24, holder_id: "HOLDER-GHA-FABLGHAC-001", institution_name: "First Atlantic Bank",           swift_code: "FABLGHAC", country_code: "GHA", public_key: "ed25519:FAB001PUBKEY" },
        { id:  25, holder_id: "HOLDER-GHA-HFBLGHAC-001", institution_name: "Republic Bank Ghana",           swift_code: "HFBLGHAC", country_code: "GHA", public_key: "ed25519:RPB_GHA001PUBKEY" },
        { id:  26, holder_id: "HOLDER-GHA-PRBLGHAC-001", institution_name: "Prudential Bank Ghana",         swift_code: "PRBLGHAC", country_code: "GHA", public_key: "ed25519:PRU_GHA001PUBKEY" },
        { id:  27, holder_id: "HOLDER-GHA-ADBKGHAC-001", institution_name: "Agricultural Development Bank", swift_code: "ADBKGHAC", country_code: "GHA", public_key: "ed25519:ADB001PUBKEY" },
        { id:  28, holder_id: "HOLDER-GHA-NIBKGHAC-001", institution_name: "National Investment Bank",      swift_code: "NIBKGHAC", country_code: "GHA", public_key: "ed25519:NIB001PUBKEY" },

        # ── SEN ───────────────────────────────────────────────────────────────
        { id:  29, holder_id: "HOLDER-SEN-BHSESNDA-001", institution_name: "Banque de l'Habitat du Sénégal", swift_code: "BHSESNDA", country_code: "SEN", public_key: "ed25519:BHS001PUBKEY" },
        { id:  30, holder_id: "HOLDER-SEN-ECOCSNDA-001", institution_name: "Ecobank Sénégal",               swift_code: "ECOCSNDA", country_code: "SEN", public_key: "ed25519:ECO_SEN001PUBKEY" },
        { id:  31, holder_id: "HOLDER-SEN-CBAOSNDA-001", institution_name: "CBAO Groupe Attijariwafa",      swift_code: "CBAOSNDA", country_code: "SEN", public_key: "ed25519:CBA001PUBKEY" },
        { id:  32, holder_id: "HOLDER-SEN-SOGESNDA-001", institution_name: "Société Générale Sénégal",      swift_code: "SOGESNDA", country_code: "SEN", public_key: "ed25519:SOG_SEN001PUBKEY" },
        { id:  33, holder_id: "HOLDER-SEN-BSSGSNDA-001", institution_name: "Banque Islamique du Sénégal",  swift_code: "BSSGSNDA", country_code: "SEN", public_key: "ed25519:BIS001PUBKEY" },
        { id:  34, holder_id: "HOLDER-SEN-UNAFSNDA-001", institution_name: "United Bank for Africa Sénégal", swift_code: "UNAFSNDA", country_code: "SEN", public_key: "ed25519:UBA_SEN001PUBKEY" },
        { id:  35, holder_id: "HOLDER-SEN-ATLBSNDA-001", institution_name: "Banque Atlantique Sénégal",    swift_code: "ATLBSNDA", country_code: "SEN", public_key: "ed25519:ATL_SEN001PUBKEY" },
        { id:  36, holder_id: "HOLDER-SEN-COBISNDA-001", institution_name: "Coris Bank Sénégal",           swift_code: "COBISNDA", country_code: "SEN", public_key: "ed25519:COR_SEN001PUBKEY" },

        # ── CIV ───────────────────────────────────────────────────────────────
        { id:  37, holder_id: "HOLDER-CIV-SOGECIAB-001", institution_name: "Société Générale Côte d'Ivoire",    swift_code: "SOGECIAB", country_code: "CIV", public_key: "ed25519:SOG_CIV001PUBKEY" },
        { id:  38, holder_id: "HOLDER-CIV-ECOCCIAB-001", institution_name: "Ecobank Côte d'Ivoire",             swift_code: "ECOCCIAB", country_code: "CIV", public_key: "ed25519:ECO_CIV001PUBKEY" },
        { id:  39, holder_id: "HOLDER-CIV-BICICIAB-001", institution_name: "BICICI",                            swift_code: "BICICIAB", country_code: "CIV", public_key: "ed25519:BIC001PUBKEY" },
        { id:  40, holder_id: "HOLDER-CIV-ATLBCIAB-001", institution_name: "Banque Atlantique Côte d'Ivoire",  swift_code: "ATLBCIAB", country_code: "CIV", public_key: "ed25519:ATL_CIV001PUBKEY" },
        { id:  41, holder_id: "HOLDER-CIV-COBICIAB-001", institution_name: "Coris Bank Côte d'Ivoire",         swift_code: "COBICIAB", country_code: "CIV", public_key: "ed25519:COR_CIV001PUBKEY" },
        { id:  42, holder_id: "HOLDER-CIV-UNAFCIAB-001", institution_name: "United Bank for Africa Côte d'Ivoire", swift_code: "UNAFCIAB", country_code: "CIV", public_key: "ed25519:UBA_CIV001PUBKEY" },
        { id:  43, holder_id: "HOLDER-CIV-BNIICIAB-001", institution_name: "Banque Nationale d'Investissement", swift_code: "BNIICIAB", country_code: "CIV", public_key: "ed25519:BNI001PUBKEY" },
        { id:  44, holder_id: "HOLDER-CIV-SCBLCIAB-001", institution_name: "Standard Chartered Côte d'Ivoire",  swift_code: "SCBLCIAB", country_code: "CIV", public_key: "ed25519:SCB_CIV001PUBKEY" },

        # ── BFA ───────────────────────────────────────────────────────────────
        { id:  45, holder_id: "HOLDER-BFA-COBIBFBF-001", institution_name: "Coris Bank International",          swift_code: "COBIBFBF", country_code: "BFA", public_key: "ed25519:COR_BFA001PUBKEY" },
        { id:  46, holder_id: "HOLDER-BFA-ECOCBFBF-001", institution_name: "Ecobank Burkina",                   swift_code: "ECOCBFBF", country_code: "BFA", public_key: "ed25519:ECO_BFA001PUBKEY" },
        { id:  47, holder_id: "HOLDER-BFA-SOGEBFBF-001", institution_name: "Société Générale Burkina Faso",     swift_code: "SOGEBFBF", country_code: "BFA", public_key: "ed25519:SOG_BFA001PUBKEY" },
        { id:  48, holder_id: "HOLDER-BFA-UNAFBFBF-001", institution_name: "United Bank for Africa Burkina",    swift_code: "UNAFBFBF", country_code: "BFA", public_key: "ed25519:UBA_BFA001PUBKEY" },
        { id:  49, holder_id: "HOLDER-BFA-ATLBBFBF-001", institution_name: "Banque Atlantique Burkina Faso",    swift_code: "ATLBBFBF", country_code: "BFA", public_key: "ed25519:ATL_BFA001PUBKEY" },
        { id:  50, holder_id: "HOLDER-BFA-AFRIBFBF-001", institution_name: "Bank of Africa Burkina Faso",       swift_code: "AFRIBFBF", country_code: "BFA", public_key: "ed25519:BOA_BFA001PUBKEY" },

        # ── MLI ───────────────────────────────────────────────────────────────
        { id:  51, holder_id: "HOLDER-MLI-BDMAMLBA-001", institution_name: "Banque de Développement du Mali",  swift_code: "BDMAMLBA", country_code: "MLI", public_key: "ed25519:BDM001PUBKEY" },
        { id:  52, holder_id: "HOLDER-MLI-ECOCMLBA-001", institution_name: "Ecobank Mali",                     swift_code: "ECOCMLBA", country_code: "MLI", public_key: "ed25519:ECO_MLI001PUBKEY" },
        { id:  53, holder_id: "HOLDER-MLI-SOGEMLBA-001", institution_name: "Société Générale Mali",            swift_code: "SOGEMLBA", country_code: "MLI", public_key: "ed25519:SOG_MLI001PUBKEY" },
        { id:  54, holder_id: "HOLDER-MLI-AFRIMLBA-001", institution_name: "Bank of Africa Mali",              swift_code: "AFRIMLBA", country_code: "MLI", public_key: "ed25519:BOA_MLI001PUBKEY" },
        { id:  55, holder_id: "HOLDER-MLI-ATLBMLBA-001", institution_name: "Banque Atlantique Mali",           swift_code: "ATLBMLBA", country_code: "MLI", public_key: "ed25519:ATL_MLI001PUBKEY" },
        { id:  56, holder_id: "HOLDER-MLI-COBIMLBA-001", institution_name: "Coris Bank Mali",                  swift_code: "COBIMLBA", country_code: "MLI", public_key: "ed25519:COR_MLI001PUBKEY" },

        # ── NER ───────────────────────────────────────────────────────────────
        { id:  57, holder_id: "HOLDER-NER-ATLANENE-001", institution_name: "Banque Atlantique Niger",          swift_code: "ATLANENE", country_code: "NER", public_key: "ed25519:ATL_NER001PUBKEY" },
        { id:  58, holder_id: "HOLDER-NER-ECOCNENE-001", institution_name: "Ecobank Niger",                    swift_code: "ECOCNENE", country_code: "NER", public_key: "ed25519:ECO_NER001PUBKEY" },
        { id:  59, holder_id: "HOLDER-NER-SNIBNENE-001", institution_name: "Société Nigérienne de Banque",     swift_code: "SNIBNENE", country_code: "NER", public_key: "ed25519:SNB001PUBKEY" },
        { id:  60, holder_id: "HOLDER-NER-AFRINENE-001", institution_name: "Bank of Africa Niger",             swift_code: "AFRINENE", country_code: "NER", public_key: "ed25519:BOA_NER001PUBKEY" },
        { id:  61, holder_id: "HOLDER-NER-COBINENE-001", institution_name: "Coris Bank Niger",                 swift_code: "COBINENE", country_code: "NER", public_key: "ed25519:COR_NER001PUBKEY" },

        # ── KEN ───────────────────────────────────────────────────────────────
        { id:  62, holder_id: "HOLDER-KEN-EQBLKENA-001", institution_name: "Equity Bank Kenya",                swift_code: "EQBLKENA", country_code: "KEN", public_key: "ed25519:EQB_KEN001PUBKEY" },
        { id:  63, holder_id: "HOLDER-KEN-KCBLKENX-001", institution_name: "KCB Bank Kenya",                  swift_code: "KCBLKENX", country_code: "KEN", public_key: "ed25519:KCB001PUBKEY" },
        { id:  64, holder_id: "HOLDER-KEN-CBAFKENA-001", institution_name: "Cooperative Bank Kenya",           swift_code: "CBAFKENA", country_code: "KEN", public_key: "ed25519:COP_KEN001PUBKEY" },
        { id:  65, holder_id: "HOLDER-KEN-SCBLKENX-001", institution_name: "Standard Chartered Kenya",         swift_code: "SCBLKENX", country_code: "KEN", public_key: "ed25519:SCB_KEN001PUBKEY" },
        { id:  66, holder_id: "HOLDER-KEN-BARCKENX-001", institution_name: "Absa Bank Kenya",                  swift_code: "BARCKENX", country_code: "KEN", public_key: "ed25519:ABS_KEN001PUBKEY" },
        { id:  67, holder_id: "HOLDER-KEN-SBICKENX-001", institution_name: "Stanbic Bank Kenya",               swift_code: "SBICKENX", country_code: "KEN", public_key: "ed25519:SBI_KEN001PUBKEY" },
        { id:  68, holder_id: "HOLDER-KEN-NCBAKENA-001", institution_name: "NCBA Bank Kenya",                  swift_code: "CBAFKENA", country_code: "KEN", public_key: "ed25519:NCB_KEN001PUBKEY" },
        { id:  69, holder_id: "HOLDER-KEN-IMBLKENA-001", institution_name: "I&M Bank Kenya",                   swift_code: "IMBLKENA", country_code: "KEN", public_key: "ed25519:IMB_KEN001PUBKEY" },
        { id:  70, holder_id: "HOLDER-KEN-DTKEKENA-001", institution_name: "Diamond Trust Bank Kenya",         swift_code: "DTKEKENA", country_code: "KEN", public_key: "ed25519:DTB001PUBKEY" },
        { id:  71, holder_id: "HOLDER-KEN-FABLKENA-001", institution_name: "Family Bank Kenya",                swift_code: "FABLKENA", country_code: "KEN", public_key: "ed25519:FAM_KEN001PUBKEY" },

        # ── UGA ───────────────────────────────────────────────────────────────
        { id:  72, holder_id: "HOLDER-UGA-SBICUGKA-001", institution_name: "Stanbic Bank Uganda",              swift_code: "SBICUGKA", country_code: "UGA", public_key: "ed25519:SBI_UGA001PUBKEY" },
        { id:  73, holder_id: "HOLDER-UGA-EQBLUGKA-001", institution_name: "Equity Bank Uganda",               swift_code: "EQBLUGKA", country_code: "UGA", public_key: "ed25519:EQB_UGA001PUBKEY" },
        { id:  74, holder_id: "HOLDER-UGA-BARCUGKA-001", institution_name: "Absa Bank Uganda",                 swift_code: "BARCUGKA", country_code: "UGA", public_key: "ed25519:ABS_UGA001PUBKEY" },
        { id:  75, holder_id: "HOLDER-UGA-CENBUGKA-001", institution_name: "Centenary Bank Uganda",            swift_code: "CENBUGKA", country_code: "UGA", public_key: "ed25519:CEN001PUBKEY" },
        { id:  76, holder_id: "HOLDER-UGA-DFCUUGKA-001", institution_name: "dfcu Bank Uganda",                 swift_code: "DFCUUGKA", country_code: "UGA", public_key: "ed25519:DFC001PUBKEY" },
        { id:  77, holder_id: "HOLDER-UGA-SCBLUGKA-001", institution_name: "Standard Chartered Uganda",        swift_code: "SCBLUGKA", country_code: "UGA", public_key: "ed25519:SCB_UGA001PUBKEY" },
        { id:  78, holder_id: "HOLDER-UGA-HFBUUGKA-001", institution_name: "Housing Finance Bank Uganda",      swift_code: "HFBUUGKA", country_code: "UGA", public_key: "ed25519:HFB001PUBKEY" },

        # ── TZA ───────────────────────────────────────────────────────────────
        { id:  79, holder_id: "HOLDER-TZA-CORUTZTZ-001", institution_name: "CRDB Bank",                        swift_code: "CORUTZTZ", country_code: "TZA", public_key: "ed25519:CRD001PUBKEY" },
        { id:  80, holder_id: "HOLDER-TZA-NMIBTZTZ-001", institution_name: "NMB Bank Tanzania",                swift_code: "NMIBTZTZ", country_code: "TZA", public_key: "ed25519:NMB001PUBKEY" },
        { id:  81, holder_id: "HOLDER-TZA-SCBLTZTZ-001", institution_name: "Standard Chartered Tanzania",      swift_code: "SCBLTZTZ", country_code: "TZA", public_key: "ed25519:SCB_TZA001PUBKEY" },
        { id:  82, holder_id: "HOLDER-TZA-SBICTZTZ-001", institution_name: "Stanbic Bank Tanzania",            swift_code: "SBICTZTZ", country_code: "TZA", public_key: "ed25519:SBI_TZA001PUBKEY" },
        { id:  83, holder_id: "HOLDER-TZA-BARCTZTZ-001", institution_name: "Absa Bank Tanzania",               swift_code: "BARCTZTZ", country_code: "TZA", public_key: "ed25519:ABS_TZA001PUBKEY" },
        { id:  84, holder_id: "HOLDER-TZA-EQBLTZTZ-001", institution_name: "Equity Bank Tanzania",             swift_code: "EQBLTZTZ", country_code: "TZA", public_key: "ed25519:EQB_TZA001PUBKEY" },
        { id:  85, holder_id: "HOLDER-TZA-KCBLTZTZ-001", institution_name: "KCB Bank Tanzania",                swift_code: "KCBLTZTZ", country_code: "TZA", public_key: "ed25519:KCB_TZA001PUBKEY" },
        { id:  86, holder_id: "HOLDER-TZA-NLCBTZTZ-001", institution_name: "NBC Bank Tanzania",                swift_code: "NLCBTZTZ", country_code: "TZA", public_key: "ed25519:NBC001PUBKEY" },

        # ── RWA ───────────────────────────────────────────────────────────────
        { id:  87, holder_id: "HOLDER-RWA-BKIGRWRW-001", institution_name: "Bank of Kigali",                   swift_code: "BKIGRWRW", country_code: "RWA", public_key: "ed25519:BOK001PUBKEY" },
        { id:  88, holder_id: "HOLDER-RWA-IMRWRWRW-001", institution_name: "I&M Bank Rwanda",                  swift_code: "IMRWRWRW", country_code: "RWA", public_key: "ed25519:IMB_RWA001PUBKEY" },
        { id:  89, holder_id: "HOLDER-RWA-EQBLRWRW-001", institution_name: "Equity Bank Rwanda",               swift_code: "EQBLRWRW", country_code: "RWA", public_key: "ed25519:EQB_RWA001PUBKEY" },
        { id:  90, holder_id: "HOLDER-RWA-KCBLRWRW-001", institution_name: "KCB Bank Rwanda",                  swift_code: "KCBLRWRW", country_code: "RWA", public_key: "ed25519:KCB_RWA001PUBKEY" },
        { id:  91, holder_id: "HOLDER-RWA-ECOCRWRW-001", institution_name: "Ecobank Rwanda",                   swift_code: "ECOCRWRW", country_code: "RWA", public_key: "ed25519:ECO_RWA001PUBKEY" },
        { id:  92, holder_id: "HOLDER-RWA-COGERWRW-001", institution_name: "Cogebanque Rwanda",                swift_code: "COGERWRW", country_code: "RWA", public_key: "ed25519:COG_RWA001PUBKEY" },

        # ── ZAF ───────────────────────────────────────────────────────────────
        { id:  93, holder_id: "HOLDER-ZAF-SBZAZAJJ-001", institution_name: "Standard Bank South Africa",       swift_code: "SBZAZAJJ", country_code: "ZAF", public_key: "ed25519:SBZ001PUBKEY" },
        { id:  94, holder_id: "HOLDER-ZAF-FIRNZAJJ-001", institution_name: "First National Bank",              swift_code: "FIRNZAJJ", country_code: "ZAF", public_key: "ed25519:FNB001PUBKEY" },
        { id:  95, holder_id: "HOLDER-ZAF-NEDSZAJJ-001", institution_name: "Nedbank",                          swift_code: "NEDSZAJJ", country_code: "ZAF", public_key: "ed25519:NED001PUBKEY" },
        { id:  96, holder_id: "HOLDER-ZAF-ABSAZAJJ-001", institution_name: "Absa Bank South Africa",           swift_code: "ABSAZAJJ", country_code: "ZAF", public_key: "ed25519:ABS_ZAF001PUBKEY" },
        { id:  97, holder_id: "HOLDER-ZAF-INVEZAJJ-001", institution_name: "Investec Bank",                    swift_code: "INVEZAJJ", country_code: "ZAF", public_key: "ed25519:INV001PUBKEY" },
        { id:  98, holder_id: "HOLDER-ZAF-CABLZAJJ-001", institution_name: "Capitec Bank",                     swift_code: "CABLZAJJ", country_code: "ZAF", public_key: "ed25519:CAP001PUBKEY" },
        { id:  99, holder_id: "HOLDER-ZAF-BIDBZAJJ-001", institution_name: "Bidvest Bank",                     swift_code: "BIDBZAJJ", country_code: "ZAF", public_key: "ed25519:BID001PUBKEY" },
        { id: 100, holder_id: "HOLDER-ZAF-DISCZA11-001", institution_name: "Discovery Bank",                   swift_code: "DISCZA11", country_code: "ZAF", public_key: "ed25519:DIS001PUBKEY" },

        # ── ZMB ───────────────────────────────────────────────────────────────
        { id: 101, holder_id: "HOLDER-ZMB-ZNCOZMLU-001", institution_name: "Zanaco",                           swift_code: "ZNCOZMLU", country_code: "ZMB", public_key: "ed25519:ZAN001PUBKEY" },
        { id: 102, holder_id: "HOLDER-ZMB-SBICZMLX-001", institution_name: "Stanbic Bank Zambia",              swift_code: "SBICZMLX", country_code: "ZMB", public_key: "ed25519:SBI_ZMB001PUBKEY" },
        { id: 103, holder_id: "HOLDER-ZMB-BARCZMLU-001", institution_name: "Absa Bank Zambia",                 swift_code: "BARCZMLU", country_code: "ZMB", public_key: "ed25519:ABS_ZMB001PUBKEY" },
        { id: 104, holder_id: "HOLDER-ZMB-FIRNZMLU-001", institution_name: "First National Bank Zambia",       swift_code: "FIRNZMLU", country_code: "ZMB", public_key: "ed25519:FNB_ZMB001PUBKEY" },
        { id: 105, holder_id: "HOLDER-ZMB-EQBLZMLU-001", institution_name: "Equity Bank Zambia",               swift_code: "EQBLZMLU", country_code: "ZMB", public_key: "ed25519:EQB_ZMB001PUBKEY" },
        { id: 106, holder_id: "HOLDER-ZMB-BKCHZMLU-001", institution_name: "Atlas Mara Bank Zambia",           swift_code: "BKCHZMLU", country_code: "ZMB", public_key: "ed25519:ATL_ZMB001PUBKEY" },

        # ── MWI ───────────────────────────────────────────────────────────────
        { id: 107, holder_id: "HOLDER-MWI-NBMAMWMW-001", institution_name: "National Bank of Malawi",          swift_code: "NBMAMWMW", country_code: "MWI", public_key: "ed25519:NBM001PUBKEY" },
        { id: 108, holder_id: "HOLDER-MWI-SBICMWMX-001", institution_name: "Standard Bank Malawi",             swift_code: "SBICMWMX", country_code: "MWI", public_key: "ed25519:SBI_MWI001PUBKEY" },
        { id: 109, holder_id: "HOLDER-MWI-FMBKMWMW-001", institution_name: "First Merchant Bank Malawi",       swift_code: "FMBKMWMW", country_code: "MWI", public_key: "ed25519:FMB001PUBKEY" },
        { id: 110, holder_id: "HOLDER-MWI-FDHBMWMW-001", institution_name: "FDH Bank Malawi",                  swift_code: "FDHBMWMW", country_code: "MWI", public_key: "ed25519:FDH001PUBKEY" },
        { id: 111, holder_id: "HOLDER-MWI-ECOCMWMW-001", institution_name: "Ecobank Malawi",                   swift_code: "ECOCMWMW", country_code: "MWI", public_key: "ed25519:ECO_MWI001PUBKEY" },

        # ── MOZ ───────────────────────────────────────────────────────────────
        { id: 112, holder_id: "HOLDER-MOZ-BCIFMZMX-001", institution_name: "BCI Fomento",                      swift_code: "BCIFMZMX", country_code: "MOZ", public_key: "ed25519:BCI001PUBKEY" },
        { id: 113, holder_id: "HOLDER-MOZ-MIBMMZMX-001", institution_name: "Millennium BIM",                   swift_code: "MIBMMZMX", country_code: "MOZ", public_key: "ed25519:MIL001PUBKEY" },
        { id: 114, holder_id: "HOLDER-MOZ-BARCMZMX-001", institution_name: "Absa Bank Moçambique",             swift_code: "BARCMZMX", country_code: "MOZ", public_key: "ed25519:ABS_MOZ001PUBKEY" },
        { id: 115, holder_id: "HOLDER-MOZ-SBICMZMX-001", institution_name: "Standard Bank Mozambique",         swift_code: "SBICMZMX", country_code: "MOZ", public_key: "ed25519:SBI_MOZ001PUBKEY" },
        { id: 116, holder_id: "HOLDER-MOZ-FIRNMZMX-001", institution_name: "First National Bank Mozambique",   swift_code: "FIRNMZMX", country_code: "MOZ", public_key: "ed25519:FNB_MOZ001PUBKEY" },

        # ── CMR ───────────────────────────────────────────────────────────────
        { id: 117, holder_id: "HOLDER-CMR-CCEICMCX-001", institution_name: "Afriland First Bank",              swift_code: "CCEICMCX", country_code: "CMR", public_key: "ed25519:AFR_CMR001PUBKEY" },
        { id: 118, holder_id: "HOLDER-CMR-ECOCCMCX-001", institution_name: "Ecobank Cameroun",                 swift_code: "ECOCCMCX", country_code: "CMR", public_key: "ed25519:ECO_CMR001PUBKEY" },
        { id: 119, holder_id: "HOLDER-CMR-SOGECMCX-001", institution_name: "Société Générale Cameroun",        swift_code: "SOGECMCX", country_code: "CMR", public_key: "ed25519:SOG_CMR001PUBKEY" },
        { id: 120, holder_id: "HOLDER-CMR-UNAFCMCX-001", institution_name: "United Bank for Africa Cameroun",  swift_code: "UNAFCMCX", country_code: "CMR", public_key: "ed25519:UBA_CMR001PUBKEY" },
        { id: 121, holder_id: "HOLDER-CMR-SCBLCMCX-001", institution_name: "Standard Chartered Cameroun",      swift_code: "SCBLCMCX", country_code: "CMR", public_key: "ed25519:SCB_CMR001PUBKEY" },
        { id: 122, holder_id: "HOLDER-CMR-ATLBCMCX-001", institution_name: "Banque Atlantique Cameroun",       swift_code: "ATLBCMCX", country_code: "CMR", public_key: "ed25519:ATL_CMR001PUBKEY" },

        # ── COG ───────────────────────────────────────────────────────────────
        { id: 123, holder_id: "HOLDER-COG-BCIACGCX-001", institution_name: "Banque Commerciale Internationale Congo", swift_code: "BCIACGCX", country_code: "COG", public_key: "ed25519:BCI_COG001PUBKEY" },
        { id: 124, holder_id: "HOLDER-COG-ECOCCGCX-001", institution_name: "Ecobank Congo",                    swift_code: "ECOCCGCX", country_code: "COG", public_key: "ed25519:ECO_COG001PUBKEY" },
        { id: 125, holder_id: "HOLDER-COG-SOGECGCX-001", institution_name: "Société Générale Congo",           swift_code: "SOGECGCX", country_code: "COG", public_key: "ed25519:SOG_COG001PUBKEY" },
        { id: 126, holder_id: "HOLDER-COG-UNAFCGCX-001", institution_name: "United Bank for Africa Congo",     swift_code: "UNAFCGCX", country_code: "COG", public_key: "ed25519:UBA_COG001PUBKEY" },

        # ── MAR ───────────────────────────────────────────────────────────────
        { id: 127, holder_id: "HOLDER-MAR-BCMAMAMC-001", institution_name: "Attijariwafa Bank",                swift_code: "BCMAMAMC", country_code: "MAR", public_key: "ed25519:ATT001PUBKEY" },
        { id: 128, holder_id: "HOLDER-MAR-BPCEAMAMC-001",institution_name: "Banque Populaire du Maroc",        swift_code: "BPCEAMAMC", country_code: "MAR", public_key: "ed25519:BPM001PUBKEY" },
        { id: 129, holder_id: "HOLDER-MAR-CIHMMAMC-001", institution_name: "CIH Bank",                         swift_code: "CIHMMAMC", country_code: "MAR", public_key: "ed25519:CIH001PUBKEY" },
        { id: 130, holder_id: "HOLDER-MAR-BMCEMAMC-001", institution_name: "BMCE Bank of Africa",              swift_code: "BMCEMAMC", country_code: "MAR", public_key: "ed25519:BMC001PUBKEY" },
        { id: 131, holder_id: "HOLDER-MAR-SOGEMAMC-001", institution_name: "Société Générale Maroc",           swift_code: "SOGEMAMC", country_code: "MAR", public_key: "ed25519:SOG_MAR001PUBKEY" },
        { id: 132, holder_id: "HOLDER-MAR-CREDMAMC-001", institution_name: "Crédit du Maroc",                  swift_code: "CREDMAMC", country_code: "MAR", public_key: "ed25519:CRE_MAR001PUBKEY" },
        { id: 133, holder_id: "HOLDER-MAR-CAMRMAMC-001", institution_name: "Crédit Agricole du Maroc",         swift_code: "CAMRMAMC", country_code: "MAR", public_key: "ed25519:CAM001PUBKEY" },
        { id: 134, holder_id: "HOLDER-MAR-BMCIMAMC-001", institution_name: "BMCI",                             swift_code: "BMCIMAMC", country_code: "MAR", public_key: "ed25519:BMI001PUBKEY" },
      ].freeze

      def index
        swift_code = params[:swift_code]&.upcase&.strip
        keys = swift_code.present?
          ? STUB_HOLDER_KEYS.select { |k| k[:swift_code] == swift_code }
          : STUB_HOLDER_KEYS
        render json: keys
      end
    end
  end
end
