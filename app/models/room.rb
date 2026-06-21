class Room < ApplicationRecord
  STATUSES = %w[waiting playing finished].freeze
  MAX_PLAYERS = 2
  COUNTDOWN_SECONDS = 3

  has_many :players, dependent: :destroy
  belongs_to :winner, class_name: "Player", optional: true

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :assign_code, on: :create

  # Public room states ---------------------------------------------------------

  def waiting?  = status == "waiting"
  def playing?  = status == "playing"
  def finished? = status == "finished"

  def full?
    players.count >= MAX_PLAYERS
  end

  def ready_to_start?
    players.count == MAX_PLAYERS
  end

  def host
    players.find_by(host: true)
  end

  # Game lifecycle -------------------------------------------------------------

  # Begin a new round: pick a fresh prompt, reset progress and schedule the
  # start a few seconds out so both clients can run the same countdown.
  def start!
    transaction do
      players.update_all(progress: 0, finished_at: nil)
      update!(
        status: "playing",
        prompt_text: Prompt.random_text,
        winner: nil,
        started_at: Time.current + COUNTDOWN_SECONDS.seconds
      )
    end
  end
  alias_method :rematch!, :start!

  # Record a finisher. Only the first one to call this becomes the winner.
  # Returns the winning player (which may be a previously recorded winner).
  def declare_winner(player)
    with_lock do
      return winner if winner_id.present?

      player.update!(finished_at: Time.current)
      update!(winner: player, status: "finished")
      player
    end
  end

  # Serializable snapshot used by the channel/front-end.
  def state_payload
    {
      status: status,
      prompt: prompt_text,
      started_at: started_at&.to_f,
      ready_to_start: ready_to_start?,
      winner_id: winner_id,
      players: players.order(:created_at).map(&:as_payload)
    }
  end

  private

  def assign_code
    return if code.present?

    self.code = loop do
      candidate = SecureRandom.alphanumeric(6).upcase
      break candidate unless Room.exists?(code: candidate)
    end
  end
end
