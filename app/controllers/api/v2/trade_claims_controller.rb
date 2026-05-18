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

        record = {
          id:             self.class.submitted_claims.length + 1,
          reference:      claim["reference"] || claim["invoice_ref"] || "TC-#{Time.now.strftime('%Y%m%d%H%M%S')}",
          corridor:       claim["corridor"]   || claim["corridor_id"],
          amount:         claim["amount"],
          currency:       claim["currency"],
          status:         "pending_review",
          submitted_by:   claim["submitted_by"] || "operator",
          created_at:     Time.now.iso8601,
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
    end
  end
end
