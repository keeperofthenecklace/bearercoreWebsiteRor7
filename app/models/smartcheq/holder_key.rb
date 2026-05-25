module Smartcheq
  # Read-only mirror of holder_keys from SmartcheqWebsiteRor7 database.
  # Returns institutional signing nodes that Module 00 operators can select.
  class HolderKey < SmartcheqRecord
    self.table_name = 'holder_keys'

    # Nodes eligible as Module 00 signing identities:
    # commercial_bank entity type OR verified institutions with a holder_id present.
    scope :signing_nodes, -> {
      where(entity_type: 'commercial_bank')
        .or(where(is_institution: true, verified: true))
        .where.not(holder_id: [nil, ''])
        .order(:name)
    }

    def display_alias
      name.presence || "#{holder_id.first(16)}..."
    end
  end
end
