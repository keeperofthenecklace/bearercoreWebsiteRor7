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
    triad.rr.com comcast.net cox.net verizon.net att.net
    earthlink.net sbcglobal.net bellsouth.net roadrunner.com
  ].freeze

  validates :name,        presence: true, length: { minimum: 4, maximum: 120 }
  validates :title,       presence: true, length: { minimum: 4, maximum: 120 }
  validates :institution, presence: true, length: { minimum: 4, maximum: 200 }
  validates :email,       presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP },
                          length: { maximum: 200 }
  validate  :institutional_email_only
  validate  :not_gibberish

  before_create { self.status ||= "pending" }

  private

  def institutional_email_only
    return if email.blank?
    domain = email.split("@").last.to_s.strip.downcase
    if CONSUMER_EMAIL_DOMAINS.include?(domain)
      errors.add(:email, "must be an institutional address — public providers (Gmail, Hotmail, Outlook, ISP mail, etc.) are not accepted")
    end
  end

  # Detect bot-generated gibberish. Real submissions have spaces and mixed case.
  # Checks applied to name, title, and institution.
  def not_gibberish
    { name: name, title: title, institution: institution }.each do |field, value|
      next if value.blank?

      # Must contain at least one space — bots fill single-word random strings
      if value.length > 12 && !value.include?(" ")
        errors.add(field, "appears invalid — please enter your #{field.to_s.humanize.downcase} in full")
        next
      end

      # Must not be all lowercase with no punctuation — proper names are capitalised
      if value == value.downcase && value !~ /[\s\-\.\,\']/
        errors.add(field, "appears invalid — please use proper capitalisation")
        next
      end

      # Consonant cluster check: >= 70% consonants = likely random string
      # (real words like "Bank", "Governor", "Nigeria" have vowel ratios around 25–45%)
      letters = value.gsub(/[^a-z]/i, "")
      if letters.length >= 6
        vowels    = letters.count("aeiouAEIOU").to_f
        consonant_ratio = 1.0 - (vowels / letters.length)
        if consonant_ratio >= 0.75
          errors.add(field, "appears invalid — please check your entry")
        end
      end
    end
  end
end
