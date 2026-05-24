module Api
  module V1
    # GET  /api/v1/operator/current_identity
    # POST /api/v1/operator/store_identity
    #
    # Session-backed identity store for Module 00. bearerCORE has no per-user
    # accounts — auth is a single shared session cookie. This controller lets
    # the frontend persist the derived holder_id server-side so it survives
    # browser cache clears across the same authenticated session.
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
    end
  end
end
