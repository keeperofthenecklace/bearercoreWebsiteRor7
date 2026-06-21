module Api
  module V2
    # Read-only health/heartbeat for the inbound RTGS reserve interface.
    # Surfaced on the Qt6 Corridor Ops gateway indicator. Unauthenticated by
    # design — exposes no payload content, only liveness metadata. (The inbound
    # webhook itself keeps its mTLS + shared-secret guard.)
    class RtgsStatusController < ApplicationController
      skip_before_action :verify_authenticity_token

      # GET /api/v2/rtgs/status
      def show
        last = Pacs009Message.order(created_at: :desc).first

        render json: {
          connected:    last.present? && last.created_at >= 24.hours.ago,
          last_sync_at: last&.created_at&.iso8601,
          last_uetr:    last&.uetr,
          count_today:  Pacs009Message.where("created_at >= ?", Time.current.beginning_of_day).count
        }
      end
    end
  end
end
