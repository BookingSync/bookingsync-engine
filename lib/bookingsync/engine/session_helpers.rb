module Bookingsync::Engine::SessionHelpers
  extend ActiveSupport::Concern

  private

  # Automatically resets authorization when the session goes inactive.
  # This is only enabled when the engine is set to embedded mode.
  def sign_out_if_inactive
    return unless Bookingsync::Engine.embedded

    last_visit = session[:_bookingsync_last_visit]
    session[:_bookingsync_last_visit] = Time.now.to_i

    if last_visit && (Time.now.to_i - last_visit > Bookingsync::Engine.sign_out_after)
      clear_authorization!
    end
  end
end
