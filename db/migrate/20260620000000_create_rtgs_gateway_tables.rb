class CreateRtgsGatewayTables < ActiveRecord::Migration[7.1]
  def change
    # 1. Raw inbound audit — every pacs.009 body received at the RTGS boundary.
    create_table :rtgs_inbound_payloads do |t|
      t.text   :raw_xml,           null: false
      t.string :client_ip_address
      t.string :tls_fingerprint

      t.timestamps
    end

    # 2. Parsed ISO 20022 metadata + idempotency ledger.
    create_table :pacs009_messages do |t|
      t.references :rtgs_inbound_payload, null: false, foreign_key: true,
                                          index: { unique: true }
      t.references :trade_claim,          foreign_key: true  # the claim this settlement produced

      t.string   :biz_msg_idr,      null: false
      t.string   :msg_def_idr,      null: false, default: "pacs.009.001.08"
      t.datetime :cre_dt
      t.string   :end_to_end_id
      t.string   :uetr
      t.string   :sender_bic
      t.string   :receiver_bic
      t.string   :currency_code,    limit: 3
      t.decimal  :settlement_amount, precision: 20, scale: 4
      t.date     :value_date
      t.string   :processing_state, null: false, default: "received"
      t.text     :error_log

      t.timestamps
    end

    # Double-submit idempotency: a (BizMsgIdr, UETR) pair is processed at most once.
    add_index :pacs009_messages, [:biz_msg_idr, :uetr], unique: true,
                                 name: "idx_pacs009_idempotency"
    add_index :pacs009_messages, :processing_state
  end
end
