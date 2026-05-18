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

        # In-process mutable proposal state — persists for the lifetime of the dev server process
        @created_proposals = []
        class << self
          attr_accessor :created_proposals
        end

        def index
          created = self.class.created_proposals
          if params[:category] == "bulk_allotment"
            per_page = (params[:per_page] || 5).to_i
            # Convert halt reconciliation events into proposal-shaped objects so
            # they surface in the Recent Allotments panel as RECALLED rows
            recon_proposals = Api::V2::CorridorsController.reconciliation_log.map do |r|
              {
                id:            r[:event_id],
                proposal_id:   r[:event_id],
                title:         "HALT RECONCILIATION — #{r[:corridor_display]}",
                corridor:      r[:corridor_display],
                corridor_id:   r[:corridor_id],
                proposal_type: "halt_reconciliation",
                amount:        r[:total_protected],
                new_cap:       r[:total_protected],
                status:        "recalled",
                submitted_by:  r[:initiated_by],
                created_at:    r[:halted_at],
                recalled_proposals: r[:recalled_proposals],
                asset_code:    r[:asset_code],
              }
            end
            allotments = recon_proposals +
                         created.select { |p| p[:proposal_type] == "bulk_allotment" } +
                         STUB_ALLOTMENTS
            render json: allotments.first(per_page)
          elsif params[:status] == "pending"
            per_page = (params[:per_page] || 20).to_i
            pending = created.select { |p| p[:status] == "pending" && p[:proposal_type] != "bulk_allotment" } + STUB_PENDING
            render json: pending.first(per_page)
          else
            render json: created + STUB_PENDING + STUB_ALLOTMENTS
          end
        end

        def create
          body = request.body.read
          data = JSON.parse(body) rescue {}
          prop = data["proposal"] || data
          next_id    = 1000 + self.class.created_proposals.length
          proposal_id = prop["title"] || "#{(prop["type"] || "PROP").upcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
          amount = prop["new_cap"].to_i

          record = {
            id:                  next_id,
            proposal_id:         proposal_id,
            title:               prop["title"] || proposal_id,
            corridor:            prop["corridor"],
            corridor_id:         prop["corridor_id"],
            proposal_type:       prop["type"] || prop["category"] || "proposal",
            amount:              amount,
            new_cap:             amount,
            required_signatures: 3,
            current_signatures:  0,
            status:              "pending",
            submitted_by:        "Governor",
            created_at:          Time.now.iso8601,
          }
          self.class.created_proposals.unshift(record)

          # Register an isolated ledger entry so this allotment can be recalled
          # independently of any concurrent injections on the same corridor
          if record[:proposal_type] == "bulk_allotment" && record[:corridor_id].present?
            Api::V2::CorridorsController.allocation_ledger << {
              proposal_id:  proposal_id,
              corridor_id:  record[:corridor_id].to_i,
              amount:       amount,
              allocated_at: Time.now,
              status:       :pending,
            }
          end

          render json: {
            status:  "submitted",
            data:    record,
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

        def recall
          # Surgically mark exactly this allocation as recalled.
          # Any other pending or confirmed allocations on the same corridor are untouched.
          entry = Api::V2::CorridorsController.allocation_ledger
                    .find { |a| a[:proposal_id] == params[:id] }

          if entry
            if entry[:status] == :confirmed
              render json: { error: "Cannot recall a confirmed allocation — funds already circulating." }, status: :unprocessable_entity
            else
              entry[:status] = :recalled
              render json: {
                status:      "recalled",
                proposal_id: params[:id],
                corridor_id: entry[:corridor_id],
                amount:      entry[:amount],
                message:     "Allocation recalled. Locked amount returned to source node. Concurrent allocations unaffected."
              }
            end
          else
            render json: { error: "Allocation not found" }, status: :not_found
          end
        end
      end
    end
  end
end
