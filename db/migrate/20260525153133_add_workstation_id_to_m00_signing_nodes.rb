class AddWorkstationIdToM00SigningNodes < ActiveRecord::Migration[7.1]
  def change
    add_column :m00_signing_nodes, :workstation_id, :string
    add_index  :m00_signing_nodes, :workstation_id
  end
end
