module Smartcheq
  class Corridor < SmartcheqRecord
    self.table_name = 'corridors'

    scope :live, -> { where(active: true, status: 'active', is_frozen: false, paused: false) }

    def effective_status
      return 'halted'  if is_frozen? || paused?
      return 'halted'  if status == 'halted'
      'active'
    end
  end
end
