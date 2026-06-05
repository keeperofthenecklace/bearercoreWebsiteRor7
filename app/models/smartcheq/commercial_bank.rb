module Smartcheq
  class CommercialBank < SmartcheqRecord
    self.table_name = 'commercial_banks'

    # One row per institution (branch-level BICs deduped), shortest SWIFT first.
    scope :for_bank_id, ->(bank_id) {
      select('DISTINCT ON (name) id, name, swift_code, "bankID", country')
        .where('"bankID" = ?', bank_id)
        .order('name, length(swift_code) ASC')
    }
  end
end
