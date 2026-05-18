module Api
  module V2
    module Governance
      class ProposalsController < ApplicationController
        skip_before_action :verify_authenticity_token

        STUB_PENDING = [
          {
            id: 1, proposal_id: "PROP-2026-001",
            title: "Raise NGA→SEN daily cap from 40M to 55M NGN",
            corridor: "NGA → SEN", corridor_id: 2,
            proposal_type: "cap_change",
            required_signatures: 3, current_signatures: 1,
            status: "pending", submitted_by: "Deputy Governor",
            created_at: "2026-05-16T08:30:00Z"
          },
          {
            id: 2, proposal_id: "PROP-2026-002",
            title: "Restore ZAF→MOZ after compliance review",
            corridor: "ZAF → MOZ", corridor_id: 9,
            proposal_type: "halt",
            required_signatures: 3, current_signatures: 2,
            status: "pending", submitted_by: "Compliance Officer",
            created_at: "2026-05-17T14:15:00Z"
          },
          {
            id: 3, proposal_id: "PROP-2026-003",
            title: "Adjust KEN→UGA rate corridor ±0.5% tolerance",
            corridor: "KEN → UGA", corridor_id: 4,
            proposal_type: "rate_adjustment",
            required_signatures: 2, current_signatures: 0,
            status: "pending", submitted_by: "Monetary Committee",
            created_at: "2026-05-18T09:00:00Z"
          },
        ].freeze

        STUB_ALLOTMENTS = [
          {
            id: 101, proposal_id: "ALOT-2026-NGA-GHA-001",
            title: "Q2 Bulk Allotment NGA→GHA", corridor: "NGA → GHA",
            proposal_type: "bulk_allotment", amount: 50_000_000, new_cap: 50_000_000,
            status: "approved", created_at: "2026-05-10T10:00:00Z"
          },
          {
            id: 102, proposal_id: "ALOT-2026-KEN-TZA-001",
            title: "Q2 Bulk Allotment KEN→TZA", corridor: "KEN → TZA",
            proposal_type: "bulk_allotment", amount: 50_000_000, new_cap: 50_000_000,
            status: "approved", created_at: "2026-05-10T10:05:00Z"
          },
          {
            id: 103, proposal_id: "ALOT-2026-ZAF-ZMB-001",
            title: "Q2 Bulk Allotment ZAF→ZMB", corridor: "ZAF → ZMB",
            proposal_type: "bulk_allotment", amount: 60_000_000, new_cap: 60_000_000,
            status: "approved", created_at: "2026-05-10T10:10:00Z"
          },
          {
            id: 104, proposal_id: "ALOT-2026-NGA-SEN-001",
            title: "Q2 Bulk Allotment NGA→SEN", corridor: "NGA → SEN",
            proposal_type: "bulk_allotment", amount: 40_000_000, new_cap: 40_000_000,
            status: "approved", created_at: "2026-05-10T10:15:00Z"
          },
          {
            id: 105, proposal_id: "ALOT-2026-CMR-NGA-001",
            title: "Q2 Bulk Allotment CMR→NGA", corridor: "CMR → NGA",
            proposal_type: "bulk_allotment", amount: 10_000_000, new_cap: 10_000_000,
            status: "pending", created_at: "2026-05-18T07:30:00Z"
          },
        ].freeze

        def index
          if params[:category] == "bulk_allotment"
            per_page = (params[:per_page] || 5).to_i
            render json: STUB_ALLOTMENTS.first(per_page)
          elsif params[:status] == "pending"
            per_page = (params[:per_page] || 20).to_i
            render json: STUB_PENDING.first(per_page)
          else
            render json: STUB_PENDING + STUB_ALLOTMENTS
          end
        end

        def create
          body = request.body.read
          data = JSON.parse(body) rescue {}
          prop = data["proposal"] || data
          proposal_id = "#{(prop["type"] || "PROP").upcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
          render json: {
            status: "submitted",
            data: {
              proposal_id: proposal_id,
              type:        prop["type"] || "proposal",
              corridor:    prop["corridor"],
              amount:      prop["new_cap"],
              status:      "pending",
              created_at:  Time.now.iso8601,
            },
            message: "Proposal #{proposal_id} submitted — awaiting multi-sig approval."
          }
        end

        def vote
          render json: {
            status:      "recorded",
            proposal_id: params[:id],
            vote:        params[:vote] || "approve",
            message:     "Signature recorded. (Demo — no state persisted.)"
          }
        end
      end
    end
  end
end
