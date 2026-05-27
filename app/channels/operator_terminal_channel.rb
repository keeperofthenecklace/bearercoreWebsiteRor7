class OperatorTerminalChannel < ApplicationCable::Channel
  def subscribed
    stream_from "issuance_clearance_channel"
  end

  def unsubscribed
    stop_all_streams
  end
end
