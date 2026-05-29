class TradeClaim < ApplicationRecord
  TERMINAL_STATES = %w[ready_to_mint rejected cancelled].freeze

  # jsonb columns store string keys. Override [] so CorridorVerificationService
  # and ClearanceBroadcaster can still do claim[:corridor][:source_country] with
  # symbol keys without modification.
  def [](key)
    val = read_attribute(key)
    case key.to_s
    when 'corridor', 'institution'
      val.is_a?(Hash) ? val.with_indifferent_access : val
    else
      val
    end
  end

  def terminal?
    TERMINAL_STATES.include?(status.to_s)
  end
end
