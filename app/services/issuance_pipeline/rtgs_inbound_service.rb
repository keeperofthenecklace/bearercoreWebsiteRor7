module IssuancePipeline
  # Turns a parsed inbound RTGS pacs.009 settlement into a *pre-cleared*
  # TradeClaim. The fiat has already moved to the Central Bank settlement
  # account, so the claim is treated as cleared out-of-band: it runs the same
  # pre-clear sequence as TradeClaimsController#approve (corridor verification →
  # SmartCHEQ corridor provision → clearance broadcast) and, when corridor
  # headroom holds, lands at `ready_to_mint` so it appears in the Qt6 SELECT
  # SOURCE dropdown without any human review step.
  class RtgsInboundService
    # BIC chars 5-6 are an ISO 3166-1 alpha-2 country code; corridors/currencies
    # in this app are keyed by alpha-3, so map across for the supported set.
    BIC_ALPHA2_TO_ALPHA3 = {
      "NG" => "NGA", "GH" => "GHA", "SN" => "SEN", "CI" => "CIV", "BF" => "BFA",
      "ML" => "MLI", "NE" => "NER", "BJ" => "BEN", "TG" => "TGO", "GW" => "GNB",
      "CV" => "CPV", "SL" => "SLE", "GM" => "GMB", "GN" => "GIN", "LR" => "LBR",
      "KE" => "KEN", "UG" => "UGA", "TZ" => "TZA", "RW" => "RWA", "BI" => "BDI",
      "SS" => "SSD", "ET" => "ETH", "ZA" => "ZAF", "ZM" => "ZMB", "MW" => "MWI",
      "MZ" => "MOZ", "ZW" => "ZWE", "BW" => "BWA", "NA" => "NAM", "LS" => "LSO",
      "SZ" => "SWZ", "AO" => "AGO", "CM" => "CMR", "CG" => "COG", "GA" => "GAB",
      "GQ" => "GNQ", "CF" => "CAF", "TD" => "TCD", "MA" => "MAR", "EG" => "EGY",
      "TN" => "TUN", "DZ" => "DZA", "LY" => "LBY", "MR" => "MRT", "SO" => "SOM",
      "DJ" => "DJI", "ER" => "ERI", "SD" => "SDN"
    }.freeze

    def initialize(pacs_message)
      @msg = pacs_message
    end

    # Returns the created TradeClaim (mutated to its post-verification status).
    def call
      src_alpha3 = country_alpha3(@msg.sender_bic)
      dst_alpha3 = country_alpha3(@msg.receiver_bic)
      corridor_id = if src_alpha3 && dst_alpha3
        "#{src_alpha3}-#{dst_alpha3}"
      else
        (src_alpha3 || dst_alpha3).to_s
      end

      corridor_record    = Api::V2::TradeClaimsController.build_corridor_record(corridor_id)
      institution_record = Api::V2::TradeClaimsController.build_institution_record_by_bic(
        @msg.sender_bic, fallback_name: @msg.sender_bic
      )

      reference = @msg.end_to_end_id.presence || @msg.biz_msg_idr

      claim = TradeClaim.new(
        reference:             "RTGS-#{reference}",
        corridor:              corridor_record,
        institution:           institution_record,
        amount:                @msg.settlement_amount,
        currency_code:         @msg.currency_code,
        trade_direction:       "inbound_rtgs",
        description:           "Auto-cleared via RTGS pacs.009 settlement (UETR #{@msg.uetr})",
        status:                "compliance_cleared",
        compliance_cleared_at: Time.current,
        submitted_by:          "RTGS_GATEWAY"
      )

      # Pre-clear sequence — identical to TradeClaimsController#approve.
      CorridorVerificationService.new(claim).execute
      claim.save!

      provision_smartcheq_corridor(claim)
      broadcast(claim)

      @msg.update!(processing_state: "cleared_to_mint", trade_claim: claim)
      claim
    end

    private

    def country_alpha3(bic)
      return nil if bic.blank?
      a2 = bic.to_s.upcase[4, 2]
      return nil if a2.blank?
      BIC_ALPHA2_TO_ALPHA3[a2] || a2
    end

    # Mirror TradeClaimsController#approve: ensure the SmartCHEQ corridor exists
    # so Qt6's adopt_clearance call succeeds even for unregistered country pairs.
    def provision_smartcheq_corridor(claim)
      return unless claim.status == "ready_to_mint"
      corridor = claim[:corridor] || {}
      src = (corridor[:source_country] || corridor["source_country"]).to_s.upcase
      dst = (corridor[:target_country] || corridor["target_country"]).to_s.upcase
      Smartcheq::Corridor.find_or_provision!(src, dst) if src.present? && dst.present?
    rescue => e
      Rails.logger.warn "[RtgsInboundService] corridor provision skipped: #{e.class}: #{e.message}"
    end

    # Emits sovereign_clearance_received only when status == ready_to_mint
    # (the broadcaster guards this internally).
    def broadcast(claim)
      IssuancePipeline::ClearanceBroadcaster.emit(claim)
    rescue => e
      Rails.logger.error "[RtgsInboundService] ClearanceBroadcaster failed: #{e.class}: #{e.message}"
    end
  end
end
