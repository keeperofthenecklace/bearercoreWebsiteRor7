# Parsed ISO 20022 pacs.009.001.08 (Financial Institution Credit Transfer)
# message. One row per unique (BizMsgIdr, UETR) settlement; the unique index
# in the schema is the authoritative idempotency guard.
class Pacs009Message < ApplicationRecord
  PROCESSING_STATES = %w[received cleared_to_mint error].freeze

  belongs_to :rtgs_inbound_payload
  belongs_to :trade_claim, optional: true

  validates :biz_msg_idr, presence: true
  validates :uetr,        presence: true
  validates :uetr,        uniqueness: { scope: :biz_msg_idr }
  validates :processing_state, inclusion: { in: PROCESSING_STATES }
end
