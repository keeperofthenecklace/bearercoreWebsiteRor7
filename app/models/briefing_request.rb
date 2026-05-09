class BriefingRequest < ApplicationRecord
  validates :name,        presence: true, length: { maximum: 120 }
  validates :title,       presence: true, length: { maximum: 120 }
  validates :institution, presence: true, length: { maximum: 200 }
  validates :email,       presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP },
                          length: { maximum: 200 }

  before_create { self.status ||= "pending" }
end
