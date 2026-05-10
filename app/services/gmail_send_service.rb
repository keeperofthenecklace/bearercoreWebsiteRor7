require "uri"
require "net/http"
require "base64"
require "json"

class GmailSendService
  CLIENT_ID     = ENV.fetch("GMAIL_CLIENT_ID",     "")
  CLIENT_SECRET = ENV.fetch("GMAIL_CLIENT_SECRET",  "")
  REFRESH_TOKEN = ENV.fetch("GMAIL_REFRESH_TOKEN",  "")
  FROM_EMAIL    = "briefing@bearercore.com"
  FROM_NAME     = "bearerCORE Briefing Desk"
  INTERNAL_TO   = ENV.fetch("BRIEFING_NOTIFY_EMAIL", "briefing@bearercore.com")

  def self.send_briefing_confirmation(briefing_request)
    new.send_confirmation(briefing_request)
  end

  def self.send_internal_notification(briefing_request)
    new.send_internal(briefing_request)
  end

  def send_confirmation(br)
    ref = br.id.to_s.rjust(4, "0")
    send_email(
      to:           br.email,
      subject:      "CONFIDENTIAL: Sovereign Briefing Coordination [Ref: #{ref}] — bearerCORE™ Protocol",
      body:         confirmation_html(br, ref),
      content_type: "text/html"
    )
  end

  def send_internal(br)
    send_email(
      to:      INTERNAL_TO,
      subject: "[bearerCORE] New Briefing Request — #{br.institution}",
      body:    internal_body(br)
    )
  end

  private

  def send_email(to:, subject:, body:, content_type: "text/plain")
    token = get_access_token!
    raw   = [
      "MIME-Version: 1.0",
      "From: #{FROM_NAME} <#{FROM_EMAIL}>",
      "To: #{to}",
      "Subject: #{subject}",
      "Content-Type: #{content_type}; charset=UTF-8",
      "",
      body
    ].join("\r\n")

    encoded = Base64.urlsafe_encode64(raw)

    uri   = URI("https://www.googleapis.com/gmail/v1/users/me/messages/send")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"]  = "application/json"
    req.body = JSON.dump({ raw: encoded })

    res = https.request(req)
    unless res.code == "200"
      Rails.logger.error "[GmailSendService] Send failed (#{res.code}): #{res.body.truncate(200)}"
    end
    res
  end

  def get_access_token!
    uri   = URI("https://oauth2.googleapis.com/token")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = URI.encode_www_form(
      client_id:     CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: REFRESH_TOKEN,
      grant_type:    "refresh_token"
    )

    res    = https.request(req)
    parsed = JSON.parse(res.body)
    token  = parsed["access_token"]
    raise "Gmail access token request failed: #{res.body}" if token.blank?
    token
  end

  def confirmation_html(br, ref)
    date    = br.created_at.strftime("%d %B %Y")
    surname = br.name.split.last
    <<~HTML
      <!DOCTYPE html>
      <html>
      <body style="font-family: Georgia, 'Times New Roman', serif; color: #1a1a1a; max-width: 620px; margin: 0 auto; padding: 40px 24px; line-height: 1.8; font-size: 15px;">

        <p style="margin: 0 0 6px;"><strong>To:</strong> #{br.name}</p>
        <p style="margin: 0 0 6px;"><strong>Authority:</strong> #{br.institution}</p>
        <p style="margin: 0 0 28px;"><strong>Date:</strong> #{date}</p>

        <p style="margin: 0 0 20px;">Governor #{surname},</p>

        <p style="margin: 0 0 16px;">We acknowledge receipt of your request for a <strong>Sovereign Briefing</strong> regarding the bearerCORE&#8482; protocol.</p>

        <p style="margin: 0 0 24px;">This communication serves as formal confirmation that your credentials have been logged under Reference ID: <strong>#{ref}</strong>. Our Protocol Desk is currently conducting the necessary verification protocols required for high-level central bank engagements.</p>

        <p style="margin: 0 0 12px;"><strong>Next Steps:</strong></p>
        <ol style="margin: 0 0 24px; padding-left: 20px;">
          <li style="margin-bottom: 10px;"><strong>Verification:</strong> Our team will finalize the review of your institutional credentials within 24&#8211;48 hours.</li>
          <li style="margin-bottom: 10px;"><strong>Scheduling:</strong> A specialized liaison from the TowerPoint Group will contact you directly to establish a secure, encrypted channel for the session.</li>
          <li style="margin-bottom: 10px;"><strong>Materials:</strong> Any preliminary documentation provided during the briefing remains under sovereign-grade confidentiality.</li>
        </ol>

        <p style="margin: 0 0 28px;">This is an automated acknowledgment. No further action is required at this time.</p>

        <p style="margin: 0 0 4px;"><strong>Respectfully,</strong></p>
        <p style="margin: 0 0 2px;"><strong>The bearerCORE&#8482; Protocol Desk</strong></p>
        <p style="margin: 0; font-style: italic;">TowerPoint Group</p>

      </body>
      </html>
    HTML
  end

  def internal_body(br)
    submitted = br.created_at.strftime("%B %d, %Y at %H:%M UTC")
    <<~TEXT
      NEW SOVEREIGN BRIEFING REQUEST
      bearerCORE™ — Protocol Desk

      Received : #{submitted}
      Ref ID   : #{br.id}

      -------------------------------------------------------

      Name        : #{br.name}
      Title       : #{br.title}
      Institution : #{br.institution}
      Email       : #{br.email}

      -------------------------------------------------------

      Action required: Vet the requestor's institution and respond
      within 24 hours by replying directly to #{br.email}.

      To mark as reviewed, update status in the admin panel.

      --
      bearerCORE™ Internal System · TowerPoint Group
    TEXT
  end
end
