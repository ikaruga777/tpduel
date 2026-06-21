class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find_by(code: params[:code].to_s.upcase)
    return reject unless @room

    @player = @room.players.find_by(token: player_token)
    return reject unless @player

    stream_for @room
    # Send the joining client the current state right away.
    transmit({ type: "lobby", **@room.state_payload })
  end

  # Host starts (or restarts) the round.
  def start(_data = {})
    reload
    return unless @player&.host?

    @room.start!
    broadcast_state("start")
  end
  alias_method :rematch, :start

  # A player reports how many leading characters they have typed correctly.
  def progress(data)
    reload
    return unless @room&.playing? && @player

    @player.update!(progress: data["progress"].to_i)
    RoomChannel.broadcast_to(@room, { type: "progress", player_id: @player.id, progress: @player.progress })
  end

  # A player reports they finished the whole prompt correctly.
  def finish(_data = {})
    reload
    return unless @room&.playing? && @player

    winner = @room.declare_winner(@player)
    broadcast_state("finished") if winner
  end

  private

  def reload
    @room = Room.find_by(code: params[:code].to_s.upcase)
    @player = @room&.players&.find_by(token: player_token)
  end

  def broadcast_state(type)
    RoomChannel.broadcast_to(@room, { type: type, **@room.state_payload })
  end
end
