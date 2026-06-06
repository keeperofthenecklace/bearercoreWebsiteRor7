module Smartcheq
  class Corridor < SmartcheqRecord
    self.table_name = 'corridors'

    scope :live, -> { where(active: true, status: 'active', is_frozen: false, paused: false) }

    # ISO-3166-alpha3 → central bank SWIFT/BIC code
    CB_CODES = {
      "NGA" => "CBNNNGLG", "GHA" => "BGHGGHAC", "KEN" => "CBKEKENA",
      "TZA" => "BKTZTZTZ", "UGA" => "BOUGUGKA", "RWA" => "BNRWRWRW",
      "ZAF" => "SARBZAJJ", "ZMB" => "BOZAZMLX", "MWI" => "RBMZMWMW",
      "MOZ" => "BCMZMZMA", "ZWE" => "RBZZWAHA", "BWA" => "BKBOBWGB",
      "NAM" => "BNNANAXX", "LSO" => "CBLS LSLS", "SWZ" => "CBSZSZMB",
      "AGO" => "BNANAOAO", "ETH" => "NBEEETAA", "EGY" => "NBEGEGCX",
      "MAR" => "BKAMMAMR", "DZA" => "BADALDA1", "TUN" => "BCTNTNTX",
      "SEN" => "BNDASNDA", "CIV" => "BCEACIAB", "CMR" => "BCEACMCM",
      "GNQ" => "BCEAGQGQ", "GAB" => "BCEAGAGA", "COG" => "BCEACGCG",
      "CAF" => "BCEACFCF", "TCD" => "BCEACTCT",
      "BFA" => "BCEABFBF", "MLI" => "BCEAMLML", "NER" => "BCEANESE",
      "BEN" => "BCEABNBN", "TGO" => "BCEAGTGT",
      "GMB" => "CBGMGMGM", "GIN" => "BCRGGNGN", "SLE" => "BSSLSLSL",
      "LBR" => "CBLRLRLR", "GNB" => "BCEAGWGW",
    }.freeze

    def effective_status
      return 'halted'  if is_frozen? || paused?
      return 'halted'  if status == 'halted'
      'active'
    end

    # Ensures a corridor record exists in SmartCHEQ for this country pair.
    # Called from bearerCORE when a claim reaches ready_to_mint so that Qt6's
    # subsequent adopt_clearance call finds a corridor and can create the auth.
    def self.find_or_provision!(src, dst)
      code = "#{src}-#{dst}"
      existing = where(source_country: src, target_country: dst, active: true).first
      existing ||= find_by(code: code)
      return existing if existing

      from_cb = CB_CODES[src] || "#{src}XXXXX"
      to_cb   = CB_CODES[dst] || "#{dst}XXXXX"

      create!(
        code:            code,
        from_cb_code:    from_cb,
        to_cb_code:      to_cb,
        from_country:    src,
        to_country:      dst,
        source_country:  src,
        target_country:  dst,
        mode:            "pilot",
        status:          "active",
        active:          true,
        per_tx_limit:    5_000_000,
        daily_limit:     50_000_000,
        name:            "#{src}–#{dst} Virtual Corridor"
      )
    rescue ActiveRecord::RecordNotUnique
      find_by(code: code)
    end
  end
end
