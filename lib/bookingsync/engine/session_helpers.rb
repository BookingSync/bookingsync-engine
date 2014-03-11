module BookingSync::Engine::SessionHelpers
  extend ActiveSupport::Concern

  included do
    before_action :sign_out_if_inactive
  end

  private

  # Automatically resets authorization when the session goes inactive.
  # This is only enabled when the engine is set to embedded mode.
  def sign_out_if_inactive
    return unless BookingSync::Engine.embedded

    last_visit = session[:_bookingsync_last_visit]
    session[:_bookingsync_last_visit] = Time.now.to_i

    if last_visit && (Time.now.to_i - last_visit > BookingSync::Engine.sign_out_after)
      reset_authorization!
    end
  end
end
