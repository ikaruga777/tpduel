class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :player_token

  # A stable per-browser identity used to tie a visitor to their Player rows.
  # No accounts: this signed cookie is the only thing identifying a player.
  def player_token
    cookies.signed[:player_token] ||= SecureRandom.uuid
  end
end
