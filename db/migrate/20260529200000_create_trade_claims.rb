class CreateTradeClaims < ActiveRecord::Migration[7.1]
  def change
    create_table :trade_claims do |t|
      t.string   :reference,                         null: false
      t.jsonb    :corridor,                          null: false, default: {}
      t.jsonb    :institution,                       null: false, default: {}
      t.decimal  :amount,                            precision: 18, scale: 4
      t.string   :currency_code
      t.string   :trade_direction
      t.string   :beneficiary_name
      t.string   :beneficiary_country
      t.text     :description
      t.string   :status,                            null: false, default: 'pending_review'
      t.string   :submitted_by
      t.text     :decision_notes
      t.text     :verification_note
      t.datetime :verification_checked_at
      t.datetime :compliance_cleared_at
      t.decimal  :earmarked_amount,                  precision: 18, scale: 4
      t.decimal  :corridor_headroom_at_verification, precision: 18, scale: 4
      t.decimal  :shortfall,                         precision: 18, scale: 4
      t.string   :asset_code
      t.datetime :rejected_at
      t.datetime :cancelled_at
      t.string   :issuance_authorization_id

      t.timestamps
    end

    add_index :trade_claims, :status
    add_index :trade_claims, :reference
    add_index :trade_claims, :created_at
  end
end
