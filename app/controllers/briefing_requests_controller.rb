class BriefingRequestsController < ApplicationController
  protect_from_forgery with: :null_session, only: [:create]

  def create
    @briefing = BriefingRequest.new(briefing_params)

    if @briefing.save
      send_emails_async(@briefing)
      render json: { success: true }, status: :created
    else
      render json: { errors: @briefing.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def briefing_params
    params.require(:briefing_request).permit(:name, :title, :institution, :email)
  end

  def send_emails_async(briefing)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        GmailSendService.send_briefing_confirmation(briefing)
        GmailSendService.send_internal_notification(briefing)
      end
    rescue => e
      Rails.logger.error "[BriefingRequests] Email failed: #{e.message}"
    end
  end
end
