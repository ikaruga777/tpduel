class RoomsController < ApplicationController
  before_action :set_room, only: %i[show join]

  # Landing page: pick a nickname and create a room.
  def new
  end

  # Host creates a room and becomes its first player.
  def create
    nickname = params[:nickname].to_s.strip
    if nickname.blank?
      redirect_to root_path, alert: "ニックネームを入力してください" and return
    end

    room = Room.new
    room.save!
    room.players.create!(nickname: nickname, token: player_token, host: true)

    redirect_to room_path(room.code)
  end

  # The room page. Shows the join form for newcomers and the game board for
  # players already in the room.
  def show
    @player = @room.players.find_by(token: player_token)
  end

  # A second visitor joins the room as the guest.
  def join
    if @room.players.exists?(token: player_token)
      redirect_to room_path(@room.code) and return
    end

    if @room.full?
      redirect_to room_path(@room.code), alert: "この部屋は満員です" and return
    end

    nickname = params[:nickname].to_s.strip
    if nickname.blank?
      redirect_to room_path(@room.code), alert: "ニックネームを入力してください" and return
    end

    @room.players.create!(nickname: nickname, token: player_token, host: false)
    RoomChannel.broadcast_to(@room, { type: "lobby", **@room.state_payload })

    redirect_to room_path(@room.code)
  end

  private

  def set_room
    @room = Room.find_by(code: params[:code].to_s.upcase)
    redirect_to root_path, alert: "部屋が見つかりません" unless @room
  end
end
