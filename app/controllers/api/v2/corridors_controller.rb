module Api
  module V2
    class CorridorsController < ApplicationController
      skip_before_action :verify_authenticity_token

      # In-process mutable state — persists for the lifetime of the dev server process.
      # @allocation_ledger: flat array of individual allocation records so each can be
      #   confirmed or recalled independently. Schema:
      #   { proposal_id: String, corridor_id: Integer, amount: Integer,
      #     allocated_at: Time, status: :pending | :confirmed | :recalled }
      # @reconciliation_log: one entry per halt event capturing what was auto-recalled.
      @halted_ids         = []
      @allocation_ledger  = []
      @reconciliation_log = []
      class << self
        attr_accessor :halted_ids, :allocation_ledger, :reconciliation_log
      end

      HANDSHAKE_WINDOW = 7  # seconds until a pending allocation auto-confirms

      STUB_CORRIDORS = [
        # ── ECOWAS — Bidirectional ────────────────────────────────────────────
        {
          id: 1, code: "NGA-GHA", corridor_display: "NGA → GHA",
          source_country: "NGA", target_country: "GHA",
          status: "active", asset_code: "NGN", daily_volume: 14_200_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 31_000_000, asset_code: "NGN" }
        },
        {
          id: 2, code: "GHA-NGA", corridor_display: "GHA → NGA",
          source_country: "GHA", target_country: "NGA",
          status: "active", asset_code: "GHS", daily_volume: 9_800_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 22_000_000, asset_code: "GHS" }
        },
        {
          id: 3, code: "NGA-SEN", corridor_display: "NGA → SEN",
          source_country: "NGA", target_country: "SEN",
          status: "active", asset_code: "NGN", daily_volume: 8_100_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 37_200_000, asset_code: "NGN" }
        },
        {
          id: 4, code: "SEN-NGA", corridor_display: "SEN → NGA",
          source_country: "SEN", target_country: "NGA",
          status: "active", asset_code: "XOF", daily_volume: 3_200_000,
          liquidity_position: { domestic_available: 200_000_000, linked_outstanding: 82_000_000, asset_code: "XOF" }
        },
        {
          id: 5, code: "GHA-CIV", corridor_display: "GHA → CIV",
          source_country: "GHA", target_country: "CIV",
          status: "active", asset_code: "GHS", daily_volume: 4_600_000,
          liquidity_position: { domestic_available: 20_000_000, linked_outstanding: 9_800_000, asset_code: "GHS" }
        },
        {
          id: 6, code: "CIV-GHA", corridor_display: "CIV → GHA",
          source_country: "CIV", target_country: "GHA",
          status: "active", asset_code: "XOF", daily_volume: 3_900_000,
          liquidity_position: { domestic_available: 180_000_000, linked_outstanding: 95_000_000, asset_code: "XOF" }
        },

        # ── AES — Alliance of Sahel States (Bidirectional) ────────────────────
        {
          id: 7, code: "BFA-MLI", corridor_display: "BFA → MLI",
          source_country: "BFA", target_country: "MLI",
          status: "active", asset_code: "XOF", daily_volume: 3_200_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 21_000_000, asset_code: "XOF" }
        },
        {
          id: 8, code: "MLI-BFA", corridor_display: "MLI → BFA",
          source_country: "MLI", target_country: "BFA",
          status: "active", asset_code: "XOF", daily_volume: 2_800_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 18_000_000, asset_code: "XOF" }
        },
        {
          id: 9, code: "BFA-NER", corridor_display: "BFA → NER",
          source_country: "BFA", target_country: "NER",
          status: "active", asset_code: "XOF", daily_volume: 1_900_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 12_000_000, asset_code: "XOF" }
        },
        {
          id: 10, code: "NER-BFA", corridor_display: "NER → BFA",
          source_country: "NER", target_country: "BFA",
          status: "active", asset_code: "XOF", daily_volume: 1_600_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 9_500_000, asset_code: "XOF" }
        },
        {
          id: 11, code: "MLI-NER", corridor_display: "MLI → NER",
          source_country: "MLI", target_country: "NER",
          status: "active", asset_code: "XOF", daily_volume: 2_100_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 15_000_000, asset_code: "XOF" }
        },
        {
          id: 12, code: "NER-MLI", corridor_display: "NER → MLI",
          source_country: "NER", target_country: "MLI",
          status: "active", asset_code: "XOF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 11_000_000, asset_code: "XOF" }
        },

        # ── EAC — Bidirectional ───────────────────────────────────────────────
        {
          id: 13, code: "KEN-UGA", corridor_display: "KEN → UGA",
          source_country: "KEN", target_country: "UGA",
          status: "active", asset_code: "KES", daily_volume: 6_300_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 12_100_000, asset_code: "KES" }
        },
        {
          id: 14, code: "UGA-KEN", corridor_display: "UGA → KEN",
          source_country: "UGA", target_country: "KEN",
          status: "active", asset_code: "UGX", daily_volume: 4_100_000,
          liquidity_position: { domestic_available: 120_000_000, linked_outstanding: 51_000_000, asset_code: "UGX" }
        },
        {
          id: 15, code: "KEN-TZA", corridor_display: "KEN → TZA",
          source_country: "KEN", target_country: "TZA",
          status: "active", asset_code: "KES", daily_volume: 9_800_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 21_000_000, asset_code: "KES" }
        },
        {
          id: 16, code: "TZA-KEN", corridor_display: "TZA → KEN",
          source_country: "TZA", target_country: "KEN",
          status: "active", asset_code: "TZS", daily_volume: 5_400_000,
          liquidity_position: { domestic_available: 250_000_000, linked_outstanding: 148_000_000, asset_code: "TZS" }
        },
        {
          id: 17, code: "KEN-RWA", corridor_display: "KEN → RWA",
          source_country: "KEN", target_country: "RWA",
          status: "active", asset_code: "KES", daily_volume: 2_200_000,
          liquidity_position: { domestic_available: 15_000_000, linked_outstanding: 4_500_000, asset_code: "KES" }
        },
        {
          id: 18, code: "RWA-KEN", corridor_display: "RWA → KEN",
          source_country: "RWA", target_country: "KEN",
          status: "active", asset_code: "RWF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 60_000_000, linked_outstanding: 22_000_000, asset_code: "RWF" }
        },

        # ── SADC — Bidirectional ──────────────────────────────────────────────
        {
          id: 19, code: "ZAF-ZMB", corridor_display: "ZAF → ZMB",
          source_country: "ZAF", target_country: "ZMB",
          status: "active", asset_code: "ZAR", daily_volume: 11_400_000,
          liquidity_position: { domestic_available: 60_000_000, linked_outstanding: 56_800_000, asset_code: "ZAR" }
        },
        {
          id: 20, code: "ZMB-ZAF", corridor_display: "ZMB → ZAF",
          source_country: "ZMB", target_country: "ZAF",
          status: "active", asset_code: "ZMW", daily_volume: 7_200_000,
          liquidity_position: { domestic_available: 600_000_000, linked_outstanding: 210_000_000, asset_code: "ZMW" }
        },
        {
          id: 21, code: "ZAF-MWI", corridor_display: "ZAF → MWI",
          source_country: "ZAF", target_country: "MWI",
          status: "active", asset_code: "ZAR", daily_volume: 3_100_000,
          liquidity_position: { domestic_available: 20_000_000, linked_outstanding: 8_200_000, asset_code: "ZAR" }
        },
        {
          id: 22, code: "MWI-ZAF", corridor_display: "MWI → ZAF",
          source_country: "MWI", target_country: "ZAF",
          status: "active", asset_code: "MWK", daily_volume: 2_400_000,
          liquidity_position: { domestic_available: 800_000_000, linked_outstanding: 240_000_000, asset_code: "MWK" }
        },
        {
          id: 23, code: "ZAF-MOZ", corridor_display: "ZAF → MOZ",
          source_country: "ZAF", target_country: "MOZ",
          status: "halted", asset_code: "ZAR", daily_volume: 0,
          liquidity_position: { domestic_available: 0, linked_outstanding: 0, asset_code: "ZAR" }
        },
        {
          id: 24, code: "MOZ-ZAF", corridor_display: "MOZ → ZAF",
          source_country: "MOZ", target_country: "ZAF",
          status: "halted", asset_code: "MZN", daily_volume: 0,
          liquidity_position: { domestic_available: 0, linked_outstanding: 0, asset_code: "MZN" }
        },

        # ── CEMAC — Bidirectional ─────────────────────────────────────────────
        {
          id: 25, code: "CMR-NGA", corridor_display: "CMR → NGA",
          source_country: "CMR", target_country: "NGA",
          status: "active", asset_code: "XAF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 10_000_000, linked_outstanding: 3_200_000, asset_code: "XAF" }
        },
        {
          id: 26, code: "NGA-CMR", corridor_display: "NGA → CMR",
          source_country: "NGA", target_country: "CMR",
          status: "active", asset_code: "NGN", daily_volume: 2_100_000,
          liquidity_position: { domestic_available: 12_000_000, linked_outstanding: 4_800_000, asset_code: "NGN" }
        },
        {
          id: 27, code: "CMR-COG", corridor_display: "CMR → COG",
          source_country: "CMR", target_country: "COG",
          status: "active", asset_code: "XAF", daily_volume: 950_000,
          liquidity_position: { domestic_available: 8_000_000, linked_outstanding: 2_900_000, asset_code: "XAF" }
        },
        {
          id: 28, code: "COG-CMR", corridor_display: "COG → CMR",
          source_country: "COG", target_country: "CMR",
          status: "active", asset_code: "XAF", daily_volume: 780_000,
          liquidity_position: { domestic_available: 6_000_000, linked_outstanding: 1_800_000, asset_code: "XAF" }
        },

        # ── AMU — Bidirectional ───────────────────────────────────────────────
        {
          id: 29, code: "MAR-SEN", corridor_display: "MAR → SEN",
          source_country: "MAR", target_country: "SEN",
          status: "active", asset_code: "MAD", daily_volume: 2_700_000,
          liquidity_position: { domestic_available: 25_000_000, linked_outstanding: 11_100_000, asset_code: "MAD" }
        },
        {
          id: 30, code: "SEN-MAR", corridor_display: "SEN → MAR",
          source_country: "SEN", target_country: "MAR",
          status: "active", asset_code: "XOF", daily_volume: 1_900_000,
          liquidity_position: { domestic_available: 150_000_000, linked_outstanding: 52_000_000, asset_code: "XOF" }
        },
      ].freeze

      def index
        per_page = (params[:per_page] || 50).to_i
        corridors = STUB_CORRIDORS.first(per_page).map { |c| apply_corridor_state(c) }
        render json: corridors
      end

      def show
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == params[:id].to_s || c[:code] == params[:id] }
        if corridor
          render json: apply_corridor_state(corridor)
        else
          render json: { error: "Corridor not found" }, status: :not_found
        end
      end

      def liquidity_position
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == params[:corridor_id].to_s || c[:code] == params[:corridor_id] }
        if corridor
          render json: { data: apply_corridor_state(corridor)[:liquidity_position] }
        else
          render json: { error: "Corridor not found" }, status: :not_found
        end
      end

      def halt
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == params[:corridor_id].to_s }
        unless corridor
          render json: { error: "Corridor not found" }, status: :not_found
          return
        end

        cid = corridor[:id]

        # Step 1 — circuit breaker: block the corridor immediately
        self.class.halted_ids |= [cid]

        # Step 2 — deterministic rollback: auto-recall every pending allocation
        # on this path. Confirmed allocations are already circulating and require
        # a separate manual reversal proposal; only :pending (uncommitted) funds
        # can be safely yanked back to the source node.
        pending = self.class.allocation_ledger.select { |a| a[:corridor_id] == cid && a[:status] == :pending }
        pending.each { |a| a[:status] = :recalled }

        # Step 3 — write a reconciliation event for the treasury audit trail
        recalled_total = pending.sum { |a| a[:amount] }
        recon = {
          event_id:           "RECON-HALT-#{cid}-#{Time.now.strftime('%Y%m%d%H%M%S')}",
          corridor_id:        cid,
          corridor_display:   corridor[:corridor_display],
          asset_code:         corridor[:asset_code],
          halted_at:          Time.now.iso8601,
          recalled_proposals: pending.map { |a| { proposal_id: a[:proposal_id], amount: a[:amount] } },
          recalled_count:     pending.length,
          total_protected:    recalled_total,
          status:             "pending_manual_clearance",
          initiated_by:       params[:initiated_by] || "governor",
        }
        self.class.reconciliation_log.unshift(recon)

        render json: {
          status:          "halted",
          corridor_id:     cid,
          reconciliation:  recon,
          message:         build_halt_message(corridor, pending, recalled_total),
        }
      end

      def reconciliation
        render json: self.class.reconciliation_log
      end

      def clear_reconciliation
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == (params[:corridor_id] || params[:id]).to_s }
        unless corridor
          render json: { error: "Corridor not found" }, status: :not_found
          return
        end
        cid = corridor[:id]
        archived = 0
        now = Time.now.iso8601
        self.class.reconciliation_log.each do |r|
          if r[:corridor_id] == cid && r[:status] == "pending_manual_clearance"
            r[:status]      = "archived"
            r[:archived_at] = now
            archived += 1
          end
        end
        render json: {
          status:          "cleared",
          corridor_id:     cid,
          events_archived: archived,
          message:         "#{archived} reconciliation event(s) archived. Corridor is now eligible for resumption."
        }
      end

      def unhalt
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == (params[:corridor_id] || params[:id]).to_s }
        unless corridor
          render json: { error: "Corridor not found" }, status: :not_found
          return
        end
        cid = corridor[:id]

        unless self.class.halted_ids.include?(cid)
          render json: { error: "Corridor is not halted." }, status: :unprocessable_entity
          return
        end

        # Pre-flight: block resumption if treasury team hasn't cleared the recon log
        open_recon = self.class.reconciliation_log.any? { |r| r[:corridor_id] == cid && r[:status] == "pending_manual_clearance" }
        if open_recon
          render json: {
            error: "Cannot resume: open halt reconciliation entries require manual clearance first.",
            hint:  "POST /api/v2/corridors/#{cid}/clear_reconciliation to acknowledge and archive."
          }, status: :unprocessable_entity
          return
        end

        self.class.halted_ids.delete(cid)
        render json: {
          status:       "active",
          corridor_id:  cid,
          message:      "#{corridor[:corridor_display]} resumed. Sovereign liquidity channel re-established."
        }
      end

      private

      def build_halt_message(corridor, recalled, total)
        base = "#{corridor[:corridor_display]} HALTED. Settlement suspended."
        if recalled.any?
          ids = recalled.map { |a| a[:proposal_id] }.join(", ")
          "#{base} #{recalled.length} pending allocation(s) auto-recalled (#{ids}). " \
            "#{corridor[:asset_code]} #{total.to_s} protected and returned to source node."
        else
          "#{base} No pending allocations were in flight."
        end
      end

      def apply_corridor_state(corridor)
        cid = corridor[:id]

        # Halt takes precedence over all allocation states
        if self.class.halted_ids.include?(cid)
          return corridor.merge(
            status: "halted",
            daily_volume: 0,
            liquidity_position: corridor[:liquidity_position].merge(domestic_available: 0, linked_outstanding: 0)
          )
        end

        entries = self.class.allocation_ledger.select { |a| a[:corridor_id] == cid }
        return corridor if entries.empty?

        # Advance any pending entries that have cleared the handshake window
        now = Time.now
        entries.each do |a|
          a[:status] = :confirmed if a[:status] == :pending && (now - a[:allocated_at]) >= HANDSHAKE_WINDOW
        end

        has_pending      = entries.any? { |a| a[:status] == :pending }
        confirmed_total  = entries.select { |a| a[:status] == :confirmed }.sum { |a| a[:amount] }

        lp = corridor[:liquidity_position]
        expanded_lp = confirmed_total > 0 \
          ? lp.merge(domestic_available: lp[:domestic_available] + confirmed_total) \
          : lp

        # "allocating" if any handshake is still in flight, otherwise reflect confirmed liquidity
        corridor.merge(
          status:            has_pending ? "allocating" : "active",
          liquidity_position: expanded_lp
        )
      end
    end
  end
end
