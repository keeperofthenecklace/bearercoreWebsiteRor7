module Api
  module V1
    # GET  /api/v1/operator/current_identity
    # POST /api/v1/operator/store_identity
    # GET  /api/v1/operator/identities
    #
    # Session-backed identity store for Module 00. bearerCORE has no per-user
    # accounts — auth is a single shared session cookie. This controller lets
    # the frontend persist the derived holder_id server-side so it survives
    # browser cache clears across the same authenticated session.
    #
    # identities reads signing nodes from the shared SmartcheqWebsiteRor7
    # database (read-only via SmartcheqRecord / Smartcheq::HolderKey).
    class OperatorController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:store_identity]
      before_action :require_central_bank_access

      def current_identity
        holder_id = session[:m00_holder_id].to_s
        if holder_id.present?
          render json: {
            status:     'authenticated',
            holder_id:  holder_id,
            node_alias: session[:m00_node_alias] || 'Commercial Bank Node'
          }
        else
          render json: { status: 'uninitialized' }, status: :not_found
        end
      end

      def store_identity
        holder_id = params[:holder_id].to_s.strip
        return render json: { error: 'holder_id required' }, status: :unprocessable_entity if holder_id.blank?

        session[:m00_holder_id]  = holder_id
        session[:m00_node_alias] = params[:node_alias].to_s.presence || 'Commercial Bank Node'
        render json: { status: 'stored', holder_id: holder_id }
      end

      def identities
        nodes = M00SigningNode.active_nodes
        render json: nodes.map { |n|
          { id: n.id, hex_string: n.holder_id, alias: n.node_alias, workstation_id: n.workstation_id }
        }
      end

      def register_node
        holder_id      = params[:holder_id].to_s.strip
        node_alias     = params[:node_alias].to_s.strip
        workstation_id = params[:workstation_id].to_s.strip.presence

        return render json: { error: 'holder_id required' }, status: :unprocessable_entity if holder_id.blank?
        return render json: { error: 'node_alias required' }, status: :unprocessable_entity if node_alias.blank?

        node = M00SigningNode.find_or_initialize_by(holder_id: holder_id)
        node.node_alias     = node_alias
        node.workstation_id = workstation_id if workstation_id
        node.active         = true
        node.save!

        render json: { status: 'registered', id: node.id, alias: node.node_alias,
                       workstation_id: node.workstation_id }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
