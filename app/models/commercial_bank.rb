class CommercialBank < ApplicationRecord
  self.table_name = 'commercial_banks'

  scope :for_country, ->(alpha3) {
    select('DISTINCT ON (name) id, name, swift_code, country_code')
      .where(country_code: alpha3)
      .order('name, length(swift_code) ASC')
  }
end
