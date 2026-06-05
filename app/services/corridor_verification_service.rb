# Protocol-Enforced State Machine: verifies that a corridor has sufficient
# reserve headroom before a supervisor-approved claim can advance to ready_to_mint.
#
# Earmarks are deducted from net headroom atomically so concurrent approvals on
# the same corridor cannot collectively over-commit available liquidity.
class CorridorVerificationService
  # Class-level earmark ledger: corridor_id (Integer) → total earmarked amount (Float).
  # Earmarks are released when a claim is cancelled or re-evaluated back to pending.
  @earmarks = Hash.new(0)
  class << self
    attr_accessor :earmarks

    def release_earmark(corridor_id, amount)
      cid = corridor_id.to_s
      @earmarks[cid] = [(@earmarks[cid].to_f - amount.to_f), 0].max
    end
  end

  def initialize(claim)
    @claim = claim
    corridor = claim[:corridor] || {}
    @corridor_id  = corridor[:id].to_s
    @corridor_src = corridor[:source_country].to_s.upcase
    @corridor_dst = corridor[:target_country].to_s.upcase
  end

  def execute
    data = Api::V2::CorridorsController.corridors_data

    # Match by code/id first, then fall back to source+target country
    raw = data.find { |c| c[:id].to_s == @corridor_id || c[:code] == @corridor_id }

    if raw.nil? && @corridor_src.present? && @corridor_dst.present?
      raw = data.find { |c| c[:source_country] == @corridor_src && c[:target_country] == @corridor_dst }
      if raw
        # Normalise corridor ID to the resolved code so earmark tracking stays consistent
        @corridor_id = raw[:id].to_s
        @claim[:corridor] = (@claim[:corridor] || {}).merge('id' => @corridor_id)
      end
    end

    return finalize("insufficient_corridor_liquidity",
                    "Corridor not found. Routing error — verify corridor registration.") unless raw

    if Api::V2::CorridorsController.halted_ids.map(&:to_s).include?(@corridor_id)
      return finalize("insufficient_corridor_liquidity",
                      "Corridor #{raw[:code]} is halted. Governor must resume the corridor " \
                      "before settlement can proceed.")
    end

    lp             = live_liquidity(raw)
    net_headroom   = lp[:domestic_available].to_f - lp[:linked_outstanding].to_f
    existing       = self.class.earmarks[@corridor_id.to_s].to_f
    free_headroom  = net_headroom - existing
    claim_amount   = @claim[:amount].to_f

    if free_headroom >= claim_amount
      # Earmark atomically — this amount is now reserved for this claim
      self.class.earmarks[@corridor_id.to_s] = existing + claim_amount

      finalize(
        "ready_to_mint",
        "Protocol check passed. #{format_amount(free_headroom, lp[:asset_code])} headroom confirmed. " \
        "#{format_amount(claim_amount, lp[:asset_code])} earmarked for settlement.",
        corridor_headroom_at_verification: free_headroom,
        earmarked_amount:                  claim_amount,
        asset_code:                        lp[:asset_code]
      )
    else
      finalize(
        "insufficient_corridor_liquidity",
        "Corridor #{raw[:code]} headroom insufficient. " \
        "Required: #{format_amount(claim_amount, lp[:asset_code])}. " \
        "Available: #{format_amount([free_headroom, 0].max, lp[:asset_code])}. " \
        "Governor liquidity injection required before settlement can proceed.",
        corridor_headroom_at_verification: [free_headroom, 0].max,
        shortfall:                         [claim_amount - free_headroom, 0].max,
        asset_code:                        lp[:asset_code]
      )
    end
  end

  private

  def live_liquidity(raw_corridor)
    # Reflect any confirmed allocations from the corridor allocation ledger.
    # Mirrors the logic in CorridorsController#apply_corridor_state so the
    # verification sees the same net position as the live corridor view.
    ledger = Api::V2::CorridorsController.allocation_ledger
    now    = Time.now
    confirmed_total = ledger
      .select { |a| a[:corridor_id].to_s == @corridor_id.to_s }
      .select { |a|
        a[:status] == :confirmed ||
        (a[:status] == :pending &&
         (now - a[:allocated_at]) >= Api::V2::CorridorsController::HANDSHAKE_WINDOW)
      }
      .sum { |a| a[:amount] }

    lp = raw_corridor[:liquidity_position]
    confirmed_total > 0 ? lp.merge(domestic_available: lp[:domestic_available] + confirmed_total) : lp
  end

  def finalize(new_status, note, extras = {})
    @claim[:status]                   = new_status
    @claim[:verification_note]        = note
    @claim[:verification_checked_at]  = Time.now.iso8601
    extras.each { |k, v| @claim[k] = v }
    @claim
  end

  def format_amount(amount, asset_code)
    "#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} #{asset_code}"
  end
end
