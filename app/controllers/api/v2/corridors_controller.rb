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

      COUNTRY_CURRENCY = {
        "NGA" => "NGN", "GHA" => "GHS", "SEN" => "XOF", "CIV" => "XOF",
        "BFA" => "XOF", "MLI" => "XOF", "NER" => "XOF",
        "KEN" => "KES", "UGA" => "UGX", "TZA" => "TZS", "RWA" => "RWF",
        "ZAF" => "ZAR", "ZMB" => "ZMW", "MWI" => "MWK", "MOZ" => "MZN",
        "CMR" => "XAF", "COG" => "XAF", "MAR" => "MAD"
      }.freeze

      # Spot rates as of 2026-05 — XOF/XAF are CFA francs pegged to EUR at 655.957;
      # all NGN cross-rates reflect current Naira float (~1 EUR ≈ 1650 NGN).
      SPOT_RATES = {
        "NGN-GHS" => 0.008475, "GHS-NGN" => 118.0,
        "XOF-NGN" => 2.516,    "NGN-XOF" => 0.3975,
        "XOF-GHS" => 0.02132,  "GHS-XOF" => 46.9,
        "KES-UGX" => 29.72,    "UGX-KES" => 0.03364,
        "KES-TZS" => 22.46,    "TZS-KES" => 0.04452,
        "KES-RWF" => 10.83,    "RWF-KES" => 0.09234,
        "ZAR-ZMW" => 2.984,    "ZMW-ZAR" => 0.3352,
        "ZAR-MWK" => 27.12,    "MWK-ZAR" => 0.03686,
        "ZAR-MZN" => 3.418,    "MZN-ZAR" => 0.2926,
        "XAF-NGN" => 2.516,    "NGN-XAF" => 0.3975,
        "XAF-XOF" => 1.0,      "XOF-XAF" => 1.0,
        "MAD-XOF" => 60.84,    "XOF-MAD" => 0.01643,
        "MAD-NGN" => 151.8,    "NGN-MAD" => 0.006587,
      }.freeze

      QUOTE_SOURCES = %w[Treasury\ Desk CBN\ Oracle Benchmark\ Rate Interbank\ Fix].freeze

      STUB_CORRIDORS = [
        # ── WAMZ — West African Monetary Zone (non-CFA, floating fiat) ────────
        {
          id: 1, code: "NGA-GHA", corridor_display: "NGA → GHA", bloc: "WAMZ",
          source_country: "NGA", target_country: "GHA",
          status: "active", asset_code: "NGN", daily_volume: 14_200_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 31_000_000, asset_code: "NGN" }
        },
        {
          id: 2, code: "GHA-NGA", corridor_display: "GHA → NGA", bloc: "WAMZ",
          source_country: "GHA", target_country: "NGA",
          status: "active", asset_code: "GHS", daily_volume: 9_800_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 22_000_000, asset_code: "GHS" }
        },

        # ── ECOWAS — Intra-bloc, cross-currency-zone ──────────────────────────
        {
          id: 3, code: "NGA-SEN", corridor_display: "NGA → SEN", bloc: "ECOWAS",
          source_country: "NGA", target_country: "SEN",
          status: "active", asset_code: "NGN", daily_volume: 8_100_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 37_200_000, asset_code: "NGN" }
        },
        {
          id: 4, code: "SEN-NGA", corridor_display: "SEN → NGA", bloc: "ECOWAS",
          source_country: "SEN", target_country: "NGA",
          status: "active", asset_code: "XOF", daily_volume: 3_200_000,
          liquidity_position: { domestic_available: 200_000_000, linked_outstanding: 82_000_000, asset_code: "XOF" }
        },
        {
          id: 5, code: "GHA-CIV", corridor_display: "GHA → CIV", bloc: "ECOWAS",
          source_country: "GHA", target_country: "CIV",
          status: "active", asset_code: "GHS", daily_volume: 4_600_000,
          liquidity_position: { domestic_available: 20_000_000, linked_outstanding: 9_800_000, asset_code: "GHS" }
        },
        {
          id: 6, code: "CIV-GHA", corridor_display: "CIV → GHA", bloc: "ECOWAS",
          source_country: "CIV", target_country: "GHA",
          status: "active", asset_code: "XOF", daily_volume: 3_900_000,
          liquidity_position: { domestic_available: 180_000_000, linked_outstanding: 95_000_000, asset_code: "XOF" }
        },

        # ── AES — Alliance of Sahel States ────────────────────────────────────
        {
          id: 7, code: "BFA-MLI", corridor_display: "BFA → MLI", bloc: "AES",
          source_country: "BFA", target_country: "MLI",
          status: "active", asset_code: "XOF", daily_volume: 3_200_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 21_000_000, asset_code: "XOF" }
        },
        {
          id: 8, code: "MLI-BFA", corridor_display: "MLI → BFA", bloc: "AES",
          source_country: "MLI", target_country: "BFA",
          status: "active", asset_code: "XOF", daily_volume: 2_800_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 18_000_000, asset_code: "XOF" }
        },
        {
          id: 9, code: "BFA-NER", corridor_display: "BFA → NER", bloc: "AES",
          source_country: "BFA", target_country: "NER",
          status: "active", asset_code: "XOF", daily_volume: 1_900_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 12_000_000, asset_code: "XOF" }
        },
        {
          id: 10, code: "NER-BFA", corridor_display: "NER → BFA", bloc: "AES",
          source_country: "NER", target_country: "BFA",
          status: "active", asset_code: "XOF", daily_volume: 1_600_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 9_500_000, asset_code: "XOF" }
        },
        {
          id: 11, code: "MLI-NER", corridor_display: "MLI → NER", bloc: "AES",
          source_country: "MLI", target_country: "NER",
          status: "active", asset_code: "XOF", daily_volume: 2_100_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 15_000_000, asset_code: "XOF" }
        },
        {
          id: 12, code: "NER-MLI", corridor_display: "NER → MLI", bloc: "AES",
          source_country: "NER", target_country: "MLI",
          status: "active", asset_code: "XOF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 40_000_000, linked_outstanding: 11_000_000, asset_code: "XOF" }
        },

        # ── EAC — East African Community ──────────────────────────────────────
        {
          id: 13, code: "KEN-UGA", corridor_display: "KEN → UGA", bloc: "EAC",
          source_country: "KEN", target_country: "UGA",
          status: "active", asset_code: "KES", daily_volume: 6_300_000,
          liquidity_position: { domestic_available: 30_000_000, linked_outstanding: 12_100_000, asset_code: "KES" }
        },
        {
          id: 14, code: "UGA-KEN", corridor_display: "UGA → KEN", bloc: "EAC",
          source_country: "UGA", target_country: "KEN",
          status: "active", asset_code: "UGX", daily_volume: 4_100_000,
          liquidity_position: { domestic_available: 120_000_000, linked_outstanding: 51_000_000, asset_code: "UGX" }
        },
        {
          id: 15, code: "KEN-TZA", corridor_display: "KEN → TZA", bloc: "EAC",
          source_country: "KEN", target_country: "TZA",
          status: "active", asset_code: "KES", daily_volume: 9_800_000,
          liquidity_position: { domestic_available: 50_000_000, linked_outstanding: 21_000_000, asset_code: "KES" }
        },
        {
          id: 16, code: "TZA-KEN", corridor_display: "TZA → KEN", bloc: "EAC",
          source_country: "TZA", target_country: "KEN",
          status: "active", asset_code: "TZS", daily_volume: 5_400_000,
          liquidity_position: { domestic_available: 250_000_000, linked_outstanding: 148_000_000, asset_code: "TZS" }
        },
        {
          id: 17, code: "KEN-RWA", corridor_display: "KEN → RWA", bloc: "EAC",
          source_country: "KEN", target_country: "RWA",
          status: "active", asset_code: "KES", daily_volume: 2_200_000,
          liquidity_position: { domestic_available: 15_000_000, linked_outstanding: 4_500_000, asset_code: "KES" }
        },
        {
          id: 18, code: "RWA-KEN", corridor_display: "RWA → KEN", bloc: "EAC",
          source_country: "RWA", target_country: "KEN",
          status: "active", asset_code: "RWF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 60_000_000, linked_outstanding: 22_000_000, asset_code: "RWF" }
        },

        # ── SADC — Southern African Development Community ──────────────────────
        {
          id: 19, code: "ZAF-ZMB", corridor_display: "ZAF → ZMB", bloc: "SADC",
          source_country: "ZAF", target_country: "ZMB",
          status: "active", asset_code: "ZAR", daily_volume: 11_400_000,
          liquidity_position: { domestic_available: 60_000_000, linked_outstanding: 56_800_000, asset_code: "ZAR" }
        },
        {
          id: 20, code: "ZMB-ZAF", corridor_display: "ZMB → ZAF", bloc: "SADC",
          source_country: "ZMB", target_country: "ZAF",
          status: "active", asset_code: "ZMW", daily_volume: 7_200_000,
          liquidity_position: { domestic_available: 600_000_000, linked_outstanding: 210_000_000, asset_code: "ZMW" }
        },
        {
          id: 21, code: "ZAF-MWI", corridor_display: "ZAF → MWI", bloc: "SADC",
          source_country: "ZAF", target_country: "MWI",
          status: "active", asset_code: "ZAR", daily_volume: 3_100_000,
          liquidity_position: { domestic_available: 20_000_000, linked_outstanding: 8_200_000, asset_code: "ZAR" }
        },
        {
          id: 22, code: "MWI-ZAF", corridor_display: "MWI → ZAF", bloc: "SADC",
          source_country: "MWI", target_country: "ZAF",
          status: "active", asset_code: "MWK", daily_volume: 2_400_000,
          liquidity_position: { domestic_available: 800_000_000, linked_outstanding: 240_000_000, asset_code: "MWK" }
        },
        {
          id: 23, code: "ZAF-MOZ", corridor_display: "ZAF → MOZ", bloc: "SADC",
          source_country: "ZAF", target_country: "MOZ",
          status: "halted", asset_code: "ZAR", daily_volume: 0,
          liquidity_position: { domestic_available: 0, linked_outstanding: 0, asset_code: "ZAR" }
        },
        {
          id: 24, code: "MOZ-ZAF", corridor_display: "MOZ → ZAF", bloc: "SADC",
          source_country: "MOZ", target_country: "ZAF",
          status: "halted", asset_code: "MZN", daily_volume: 0,
          liquidity_position: { domestic_available: 0, linked_outstanding: 0, asset_code: "MZN" }
        },

        # ── CEMAC — Intra-bloc (both countries in Central African franc zone) ──
        {
          id: 27, code: "CMR-COG", corridor_display: "CMR → COG", bloc: "CEMAC",
          source_country: "CMR", target_country: "COG",
          status: "active", asset_code: "XAF", daily_volume: 950_000,
          liquidity_position: { domestic_available: 8_000_000, linked_outstanding: 2_900_000, asset_code: "XAF" }
        },
        {
          id: 28, code: "COG-CMR", corridor_display: "COG → CMR", bloc: "CEMAC",
          source_country: "COG", target_country: "CMR",
          status: "active", asset_code: "XAF", daily_volume: 780_000,
          liquidity_position: { domestic_available: 6_000_000, linked_outstanding: 1_800_000, asset_code: "XAF" }
        },

        # ── AfCFTA — Inter-Bloc / Cross-Zone Corridors ────────────────────────
        {
          id: 25, code: "CMR-NGA", corridor_display: "CMR → NGA", bloc: "AfCFTA",
          source_country: "CMR", target_country: "NGA",
          status: "active", asset_code: "XAF", daily_volume: 1_800_000,
          liquidity_position: { domestic_available: 10_000_000, linked_outstanding: 3_200_000, asset_code: "XAF" }
        },
        {
          id: 26, code: "NGA-CMR", corridor_display: "NGA → CMR", bloc: "AfCFTA",
          source_country: "NGA", target_country: "CMR",
          status: "active", asset_code: "NGN", daily_volume: 2_100_000,
          liquidity_position: { domestic_available: 12_000_000, linked_outstanding: 4_800_000, asset_code: "NGN" }
        },
        {
          id: 29, code: "MAR-SEN", corridor_display: "MAR → SEN", bloc: "AfCFTA",
          source_country: "MAR", target_country: "SEN",
          status: "active", asset_code: "MAD", daily_volume: 2_700_000,
          liquidity_position: { domestic_available: 25_000_000, linked_outstanding: 11_100_000, asset_code: "MAD" }
        },
        {
          id: 30, code: "SEN-MAR", corridor_display: "SEN → MAR", bloc: "AfCFTA",
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
        cid = params[:corridor_id] || params[:id]
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == cid.to_s || c[:code] == cid }
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

      def fx_quotes
        cid      = (params[:corridor_id] || params[:id]).to_s
        corridor = STUB_CORRIDORS.find { |c| c[:id].to_s == cid || c[:code] == cid }

        if corridor
          src_asset     = corridor[:asset_code].to_s
          dest_asset    = COUNTRY_CURRENCY[corridor[:target_country].to_s] || corridor[:target_country].to_s
          src           = corridor[:source_country]
          dst           = corridor[:target_country]
          corridor_code = corridor[:code]
        elsif cid =~ /\A([A-Z]{2,3})-([A-Z]{2,3})\z/i
          # Virtual corridor pseudo-ID e.g. "KEN-GHA" — derive currencies from country map
          src           = $1.upcase
          dst           = $2.upcase
          src_asset     = COUNTRY_CURRENCY[src] || src
          dest_asset    = COUNTRY_CURRENCY[dst] || dst
          corridor_code = cid
        else
          return render json: { error: "Corridor not found" }, status: :not_found
        end

        date = Time.now.strftime("%Y-%m-%d")

        # Live rate from API; fall back to static table if unreachable
        base_rate = FxRateService.rate(src_asset, dest_asset) ||
                    SPOT_RATES["#{src_asset}-#{dest_asset}"] ||
                    1.0

        precision = base_rate < 0.01 ? 6 : base_rate < 1 ? 4 : base_rate < 100 ? 2 : 0

        quotes = 3.times.map do |i|
          spread   = base_rate * (0.9985 + (i * 0.001))
          rate_v   = spread.round(precision)
          {
            id:            "FX-#{src}-#{dst}-#{date}-#{format('%03d', i + 1)}A",
            rate:          "1 #{src_asset} = #{rate_v} #{dest_asset}",
            source:        QUOTE_SOURCES[i] || "Treasury Desk",
            expires:       "#{date}T23:59:59Z",
            corridor_code: corridor_code
          }
        end

        render json: quotes
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
