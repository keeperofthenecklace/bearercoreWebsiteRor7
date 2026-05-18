module Api
  module V2
    class DocumentsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        render json: []
      end

      def create
        render json: {
          id:         SecureRandom.uuid,
          filename:   params[:filename] || "document.pdf",
          status:     "uploaded",
          created_at: Time.now.iso8601,
        }, status: :created
      end
    end
  end
end
