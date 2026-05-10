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
    send_plain(
      to:      br.email,
      subject: "Your Sovereign Briefing Request — bearerCORE™",
      body:    confirmation_body(br)
    )
  end

  def send_internal(br)
    send_plain(
      to:      INTERNAL_TO,
      subject: "[bearerCORE] New Briefing Request — #{br.institution}",
      body:    internal_body(br)
    )
  end

  private

  def send_plain(to:, subject:, body:)
    token = get_access_token!
    raw   = [
      "MIME-Version: 1.0",
      "From: #{FROM_NAME} <#{FROM_EMAIL}>",
      "To: #{to}",
      "Subject: #{subject}",
      "Content-Type: text/plain; charset=UTF-8",
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

  def confirmation_body(br)
    submitted = br.created_at.strftime("%B %d, %Y at %H:%M UTC")
    <<~TEXT
      #{br.name}
      #{br.title}
      #{br.institution}


      Your request for a Sovereign Briefing with the bearerCORE™ protocol team
      has been received and logged.

      Our team will review your credentials and contact you at this address to
      coordinate a secure, private session. You will not be added to any
      mailing list.

      Request reference : #{br.id}
      Submitted         : #{submitted}


      bearerCORE™ Protocol Desk
      TowerPoint Group

      This is an automated transmission. Please do not reply to this address.
      All communications from the bearerCORE™ team originate from
      @bearercore.com addresses.
    TEXT
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
