module IssuancePipeline
  class ClearanceBroadcaster
    def self.emit(claim)
      return false unless claim[:status] == "ready_to_mint"

      corridor = claim[:corridor] || {}
      src      = corridor[:source_country].to_s
      dst      = corridor[:target_country].to_s

      ActionCable.server.broadcast(
        "issuance_clearance_channel",
        {
          event:            "sovereign_clearance_received",
          authorization_id: claim[:reference],
          asset_code:       corridor[:asset_code] || "—",
          total_amount:     claim[:amount],
          corridor_display: src.present? && dst.present? ? "#{src} → #{dst}" : "—",
          institution:      (claim[:institution] || {})[:name] || "—",
          status:           "CLEARED",
          timestamp:        Time.current.to_i
        }
      )
      true
    end
  end
end
