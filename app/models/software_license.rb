class SoftwareLicense < ApplicationRecord
  scope :active_licenses, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc).limit(10) }
end
