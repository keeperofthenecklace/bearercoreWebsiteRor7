module Api
  module V2
    class TradeClaimsController < ApplicationController
      skip_before_action :verify_authenticity_token

      CLAIMS_STORE_PATH = Rails.root.join("tmp", "store", "trade_claims_store.json").freeze

      class << self
        def submitted_claims
          @submitted_claims ||= load_claims_from_disk
        end

        def submitted_claims=(val)
          @submitted_claims = val
        end

        def persist_claims!
          FileUtils.mkdir_p(File.dirname(CLAIMS_STORE_PATH))
          File.write(CLAIMS_STORE_PATH, @submitted_claims.to_json)
        rescue => e
          Rails.logger.warn "[TradeClaimsController] persist_claims! failed: #{e.message}"
        end

        def load_claims_from_disk
          raw = JSON.parse(File.read(CLAIMS_STORE_PATH), symbolize_names: true)
          raw.is_a?(Array) ? raw : []
        rescue
          []
        end
      end

      def index
        render json: self.class.submitted_claims
      end

      # GET /api/v2/trade_claims/clearance
      # Returns the latest ready_to_mint claim as a flat JSON object,
      # or { status: "none" } if no cleared claim exists.
      def clearance
        ready = self.class.submitted_claims.select { |c| c[:status] == "ready_to_mint" }
        if ready.any?
          render json: { status: "ready_to_mint", claim: ready.first, claims: ready }
        else
          render json: { status: "none", claims: [] }
        end
      end

      def create
        body = request.body.read
        data = JSON.parse(body) rescue {}
        claim = data["trade_claim"] || data

        corridor_id  = (claim["corridor_id"] || claim["corridor"]).to_s
        corridor_obj = Api::V2::CorridorsController::STUB_CORRIDORS.find { |c| c[:id].to_s == corridor_id }

        institution_id  = claim["institution_id"].to_s
        all_banks       = Api::V2::CommercialBanksController::STUB_BANKS.values.flatten
        institution_obj = all_banks.find { |b| b[:id].to_s == institution_id }

        corridor_record = if corridor_obj
          {
            id:             corridor_obj[:id],
            name:           "#{corridor_obj[:source_country]}–#{corridor_obj[:target_country]} Corridor",
            code:           corridor_obj[:code],
            source_country: corridor_obj[:source_country],
            target_country: corridor_obj[:target_country],
            bloc:           corridor_obj[:bloc],
            asset_code:     corridor_obj[:asset_code],
          }
        elsif corridor_id =~ /\A__virtual__([A-Z]{2,3})__([A-Z]{2,3})\z/i
          src = $1.upcase; dst = $2.upcase
          {
            id:             corridor_id,
            name:           "#{src}–#{dst} Virtual Corridor",
            code:           "#{src}-#{dst}",
            source_country: src,
            target_country: dst
          }
        elsif corridor_id =~ /\A([A-Z]{2,3})-([A-Z]{2,3})\z/i
          src = $1.upcase; dst = $2.upcase
          {
            id:             corridor_id,
            name:           "#{src}–#{dst} Corridor",
            code:           corridor_id,
            source_country: src,
            target_country: dst
          }
        else
          { id: corridor_id, name: corridor_id }
        end

        institution_record = if institution_obj
          {
            id:           institution_obj[:id],
            name:         institution_obj[:name],
            swift_code:   institution_obj[:swift_code],
            country_code: institution_obj[:country_code],
          }
        else
          { id: institution_id, name: claim["institution_name"] || "Unknown" }
        end

        record = {
          id:                  self.class.submitted_claims.length + 1,
          reference:           claim["reference"] || claim["invoice_ref"] || "TC-#{Time.now.strftime('%Y%m%d%H%M%S')}",
          corridor:            corridor_record,
          institution:         institution_record,
          amount:              claim["amount"],
          currency_code:       claim["currency_code"] || claim["currency"],
          trade_direction:     claim["trade_direction"],
          beneficiary_name:    claim["beneficiary_name"],
          beneficiary_country: claim["beneficiary_country"],
          description:         claim["description"],
          status:              "pending_review",
          submitted_by:        claim["submitted_by"] || institution_record[:name] || "operator",
          created_at:          Time.now.iso8601,
        }
        self.class.submitted_claims.unshift(record)
        self.class.persist_claims!

        render json: {
          status:  "submitted",
          data:    record,
          message: "Trade claim #{record[:reference]} submitted — entering supervisory review queue."
        }, status: :created
      end

      def draft
        body = request.body.read
        data = JSON.parse(body) rescue {}
        claim = data["trade_claim"] || data

        render json: {
          status: "draft_saved",
          data: {
            draft_id:   "DRAFT-#{Time.now.strftime('%Y%m%d%H%M%S')}",
            corridor:   claim["corridor"] || claim["corridor_id"],
            amount:     claim["amount"],
            created_at: Time.now.iso8601,
          },
          message: "Draft saved. (Demo — not persisted across server restarts.)"
        }
      end

      # Two-step Protocol-Enforced State Machine:
      #
      #   Step 1 — Supervisor approval sets status: compliance_cleared
      #            (human governance layer has signed off)
      #
      #   Step 2 — CorridorVerificationService runs the algorithmic check:
      #     → ready_to_mint                 (corridor headroom confirmed; amount earmarked)
      #     → insufficient_corridor_liquidity (headroom depleted; Governor injection required)
      #
      # Jumping straight to "approved" would allow Qt6 to attempt minting against
      # a depleted corridor reserve — this two-step prevents that.
      def approve
        claim = find_claim or return
        return render_terminal_state_error(claim) if terminal_state?(claim[:status])

        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || body["decision_notes"] || ""

        # Step 1: compliance cleared — supervisor has authorised
        claim[:status]                = "compliance_cleared"
        claim[:compliance_cleared_at] = Time.now.iso8601
        claim[:decision_notes]        = notes if notes.present?

        # Step 2: automated corridor protocol verification
        CorridorVerificationService.new(claim).execute

        # Push real-time clearance event to desktop operator terminal
        IssuancePipeline::ClearanceBroadcaster.emit(claim)
        self.class.persist_claims!

        render json: {
          status: claim[:status],
          data:   claim,
          eligibility: build_eligibility(claim),
          message: approval_message(claim),
        }
      end

      def reject
        claim = find_claim or return
        return render_terminal_state_error(claim) if terminal_state?(claim[:status])

        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || body["decision_notes"] || ""

        # Release any corridor earmark if this claim had already been verified
        if claim[:status] == "ready_to_mint"
          CorridorVerificationService.release_earmark(
            (claim[:corridor] || {})[:id], claim[:earmarked_amount].to_f
          )
        end

        claim[:status]         = "rejected"
        claim[:rejected_at]    = Time.now.iso8601
        claim[:decision_notes] = notes
        self.class.persist_claims!

        render json: {
          status:  "rejected",
          data:    claim,
          message: "Trade claim #{claim[:reference]} rejected."
        }
      end

      # Re-evaluate is the Governor's escape hatch for insufficient_corridor_liquidity:
      # if liquidity has been injected since the last check, the claim can advance
      # to ready_to_mint without requiring a full re-submission.
      def re_evaluate
        claim = find_claim or return

        if claim[:status] == "insufficient_corridor_liquidity"
          CorridorVerificationService.new(claim).execute
        end
        self.class.persist_claims!

        render json: {
          status:      claim[:status],
          data:        claim,
          eligibility: build_eligibility(claim),
          message:     re_evaluate_message(claim),
        }
      end

      def request_clarification
        claim = find_claim or return
        return render_terminal_state_error(claim) if terminal_state?(claim[:status])

        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || ""

        claim[:status]         = "clarification_requested"
        claim[:decision_notes] = notes
        self.class.persist_claims!

        render json: {
          status:  "clarification_requested",
          data:    claim,
          message: "Clarification requested on #{claim[:reference]}."
        }
      end

      def cancel
        claim = find_claim or return

        # Release earmark so the corridor headroom is restored for other claims
        if claim[:status] == "ready_to_mint"
          CorridorVerificationService.release_earmark(
            (claim[:corridor] || {})[:id], claim[:earmarked_amount].to_f
          )
        end

        claim[:status]       = "cancelled"
        claim[:cancelled_at] = Time.now.iso8601
        self.class.persist_claims!

        render json: {
          status:  "cancelled",
          data:    claim,
          message: "Trade claim #{claim[:reference]} cancelled."
        }
      end

      private

      TERMINAL_STATES = %w[approved ready_to_mint rejected cancelled].freeze

      def terminal_state?(status)
        TERMINAL_STATES.include?(status.to_s)
      end

      def render_terminal_state_error(claim)
        render json: {
          error:  "Action not permitted — claim #{claim[:reference]} is in terminal state: #{claim[:status]}.",
          status: claim[:status],
        }, status: :unprocessable_entity
      end

      def build_eligibility(claim)
        minting_ready = claim[:status] == "ready_to_mint"
        liq_ok        = minting_ready
        supervisor_ok = %w[compliance_cleared ready_to_mint insufficient_corridor_liquidity].include?(claim[:status].to_s)
        {
          issuance_eligible: minting_ready,
          gates: {
            supervisor_approval: { passed: supervisor_ok,  note: supervisor_ok ? "Supervisor approved" : "Awaiting supervisor review" },
            compliance:          { passed: supervisor_ok,  note: supervisor_ok ? "Compliance cleared" : "Not evaluated" },
            corridor_limits:     { passed: minting_ready,  note: minting_ready ? "Within corridor limits" : "Not confirmed" },
            liquidity:           { passed: liq_ok,         note: liq_ok ? "Headroom confirmed and earmarked" : (claim[:verification_note] || "Not confirmed") },
            governance:          { passed: minting_ready,  note: minting_ready ? "No governance blocks" : "Awaiting liquidity confirmation" },
          }
        }
      end

      def approval_message(claim)
        case claim[:status]
        when "ready_to_mint"
          "Trade claim #{claim[:reference]} — compliance cleared and corridor protocol verified. " \
          "Status: READY TO MINT. Qt6 issuance authorised."
        when "insufficient_corridor_liquidity"
          "Trade claim #{claim[:reference]} — compliance cleared by supervisor. " \
          "⚠ Corridor protocol check failed: #{claim[:verification_note]} " \
          "Governor liquidity injection required before minting can proceed."
        else
          "Trade claim #{claim[:reference]} — processing."
        end
      end

      def re_evaluate_message(claim)
        case claim[:status]
        when "ready_to_mint"
          "Re-evaluation complete. Corridor headroom confirmed — claim advanced to READY TO MINT."
        when "insufficient_corridor_liquidity"
          "Re-evaluation complete. Corridor headroom still insufficient. #{claim[:verification_note]}"
        else
          "Re-evaluation complete. Current status: #{claim[:status]}."
        end
      end

      def find_claim
        claim = self.class.submitted_claims.find { |c| c[:id].to_s == params[:id].to_s }
        render json: { error: "Trade claim not found" }, status: :not_found unless claim
        claim
      end
    end
  end
end
