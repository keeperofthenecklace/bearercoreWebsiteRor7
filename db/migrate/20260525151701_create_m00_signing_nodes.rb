class CreateM00SigningNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :m00_signing_nodes do |t|
      t.string  :node_alias,  null: false
      t.string  :holder_id,   null: false
      t.boolean :active,      null: false, default: true

      t.timestamps
    end
    add_index :m00_signing_nodes, :holder_id, unique: true
  end
end
