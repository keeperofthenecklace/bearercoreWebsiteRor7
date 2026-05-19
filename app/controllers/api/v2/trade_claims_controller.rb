module Api
  module V2
    class TradeClaimsController < ApplicationController
      skip_before_action :verify_authenticity_token

      @submitted_claims = []
      class << self
        attr_accessor :submitted_claims
      end

      def index
        render json: self.class.submitted_claims
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
        else
          { id: corridor_id, name: corridor_id }
        end

        institution_record = if institution_obj
          {
            id:          institution_obj[:id],
            name:        institution_obj[:name],
            swift_code:  institution_obj[:swift_code],
            country_code: institution_obj[:country_code],
          }
        else
          { id: institution_id, name: claim["institution_name"] || "Unknown" }
        end

        record = {
          id:              self.class.submitted_claims.length + 1,
          reference:       claim["reference"] || claim["invoice_ref"] || "TC-#{Time.now.strftime('%Y%m%d%H%M%S')}",
          corridor:        corridor_record,
          institution:     institution_record,
          amount:          claim["amount"],
          currency_code:   claim["currency_code"] || claim["currency"],
          trade_direction: claim["trade_direction"],
          beneficiary_name:    claim["beneficiary_name"],
          beneficiary_country: claim["beneficiary_country"],
          description:     claim["description"],
          status:          "pending_review",
          submitted_by:    claim["submitted_by"] || institution_record[:name] || "operator",
          created_at:      Time.now.iso8601,
        }
        self.class.submitted_claims.unshift(record)

        render json: { status: "submitted", data: record, message: "Trade claim #{record[:reference]} submitted — entering supervisory review queue." }, status: :created
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

      def approve
        claim = find_claim or return
        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || body["decision_notes"] || ""

        claim[:status]          = "approved"
        claim[:approved_at]     = Time.now.iso8601
        claim[:decision_notes]  = notes

        render json: {
          status:  "approved",
          data:    claim,
          eligibility: {
            issuance_eligible: true,
            gates: {
              supervisor_approval: { passed: true },
              compliance:          { passed: true },
              corridor_limits:     { passed: true },
              liquidity:           { passed: true },
              governance:          { passed: true },
            }
          },
          message: "Trade claim #{claim[:reference]} approved."
        }
      end

      def reject
        claim = find_claim or return
        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || body["decision_notes"] || ""

        claim[:status]         = "rejected"
        claim[:rejected_at]    = Time.now.iso8601
        claim[:decision_notes] = notes

        render json: { status: "rejected", data: claim, message: "Trade claim #{claim[:reference]} rejected." }
      end

      def re_evaluate
        claim = find_claim or return

        render json: {
          status: claim[:status],
          data:   claim,
          eligibility: {
            issuance_eligible: claim[:status] == "approved",
            gates: {
              supervisor_approval: { passed: claim[:status] == "approved" },
              compliance:          { passed: true },
              corridor_limits:     { passed: true },
              liquidity:           { passed: true },
              governance:          { passed: true },
            }
          },
          message: "Re-evaluation complete."
        }
      end

      def request_clarification
        claim = find_claim or return
        body  = JSON.parse(request.body.read) rescue {}
        notes = body["notes"] || ""

        claim[:status]         = "clarification_requested"
        claim[:decision_notes] = notes

        render json: { status: "clarification_requested", data: claim, message: "Clarification requested on #{claim[:reference]}." }
      end

      def cancel
        claim = find_claim or return

        claim[:status]      = "cancelled"
        claim[:cancelled_at] = Time.now.iso8601

        render json: { status: "cancelled", data: claim, message: "Trade claim #{claim[:reference]} cancelled." }
      end

      private

      def find_claim
        claim = self.class.submitted_claims.find { |c| c[:id].to_s == params[:id].to_s }
        render json: { error: "Trade claim not found" }, status: :not_found unless claim
        claim
      end
    end
  end
end
