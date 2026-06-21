class Player < ApplicationRecord
  belongs_to :room

  validates :nickname, presence: true, length: { maximum: 20 }
  validates :token, presence: true

  def finished?
    finished_at.present?
  end

  def as_payload
    {
      id: id,
      nickname: nickname,
      host: host,
      progress: progress,
      finished: finished?
    }
  end
end
