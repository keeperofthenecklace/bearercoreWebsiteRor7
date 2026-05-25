class M00SigningNode < ApplicationRecord
  validates :node_alias, presence: true
  validates :holder_id,  presence: true, uniqueness: true, length: { is: 64 },
                         format: { with: /\A[0-9a-f]{64}\z/, message: "must be a 64-char lowercase hex string" }

  scope :active_nodes, -> { where(active: true).order(:node_alias) }

  def workstation_short
    workstation_id.present? ? "#{workstation_id.first(8)}...#{workstation_id.last(4)}" : nil
  end
end
