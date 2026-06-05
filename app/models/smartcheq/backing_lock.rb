module Smartcheq
  class BackingLock < SmartcheqRecord
    self.table_name = 'backing_locks'

    scope :locked, -> { where(lock_status: 'locked') }
  end
end
