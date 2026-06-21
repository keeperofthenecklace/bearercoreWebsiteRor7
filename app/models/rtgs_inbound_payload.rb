# Raw audit row for a single inbound RTGS pacs.009 message captured at the
# bearerCORE settlement boundary, before parsing/idempotency resolution.
class RtgsInboundPayload < ApplicationRecord
  has_one :pacs009_message, dependent: :destroy
end
