class BriefingRequest < ApplicationRecord
  CONSUMER_EMAIL_DOMAINS = %w[
    gmail.com googlemail.com
    hotmail.com hotmail.co.uk hotmail.fr hotmail.es hotmail.de hotmail.it
    outlook.com outlook.co.uk outlook.fr outlook.de outlook.es outlook.it outlook.com.au
    live.com live.co.uk live.fr live.de live.com.au
    msn.com
    yahoo.com yahoo.co.uk yahoo.fr yahoo.de yahoo.es yahoo.it yahoo.com.au yahoo.co.in
    icloud.com me.com mac.com
    aol.com
    protonmail.com proton.me
    mail.com
    yandex.com yandex.ru
    qq.com 163.com 126.com
    rediffmail.com
    gmx.com gmx.de gmx.net gmx.at
    web.de t-online.de
    orange.fr free.fr sfr.fr wanadoo.fr
    virginmedia.com btinternet.com sky.com talktalk.net
  ].freeze

  validates :name,        presence: true, length: { maximum: 120 }
  validates :title,       presence: true, length: { maximum: 120 }
  validates :institution, presence: true, length: { maximum: 200 }
  validates :email,       presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP },
                          length: { maximum: 200 }
  validate  :institutional_email_only

  before_create { self.status ||= "pending" }

  private

  def institutional_email_only
    return if email.blank?
    domain = email.split("@").last.to_s.strip.downcase
    if CONSUMER_EMAIL_DOMAINS.include?(domain)
      errors.add(:email, "must be an institutional address — public providers (Gmail, Hotmail, Outlook, etc.) are not accepted")
    end
  end
end
