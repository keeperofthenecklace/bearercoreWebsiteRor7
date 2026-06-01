class BriefingRequestsController < ApplicationController
  protect_from_forgery with: :null_session, only: [:create]

  RATE_LIMIT_MAX    = 3     # max submissions per IP per window
  RATE_LIMIT_WINDOW = 3600  # 1 hour in seconds

  def create
    # ── Honeypot: the `website` field is CSS-hidden; only bots fill it ────────
    # Return a fake 201 so bots think they succeeded and don't retry.
    if params.dig(:briefing_request, :website).present?
      Rails.logger.warn "[BriefingRequest] Honeypot triggered from #{request.remote_ip}"
      render json: { success: true }, status: :created and return
    end

    # ── Form timing: legitimate users take at least 3 seconds to fill a form ──
    rendered_at = params[:form_rendered_at].to_i
    elapsed     = Time.now.to_i - rendered_at
    if rendered_at > 0 && elapsed < 3
      Rails.logger.warn "[BriefingRequest] Submission too fast (#{elapsed}s) from #{request.remote_ip}"
      render json: { success: true }, status: :created and return
    end

    # ── IP rate limit: max 3 submissions per IP per hour ──────────────────────
    cache_key = "briefing_ip:#{request.remote_ip}"
    count     = Rails.cache.read(cache_key).to_i
    if count >= RATE_LIMIT_MAX
      render json: { errors: ["Too many requests. Please try again later."] },
             status: :too_many_requests and return
    end

    @briefing = BriefingRequest.new(briefing_params)

    if @briefing.save
      Rails.cache.write(cache_key, count + 1, expires_in: RATE_LIMIT_WINDOW)
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
