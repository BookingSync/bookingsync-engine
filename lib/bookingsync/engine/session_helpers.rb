module BookingSync::Engine::SessionHelpers
  extend ActiveSupport::Concern

  included do
    before_filter :safari_iframe_cookie_fix, if: -> { BookingSync::Engine.embedded }
  end

  private

  # Automatically resets authorization when the session goes inactive.
  # This is only enabled when the engine is set to embedded mode.
  def sign_out_if_inactive
    return unless BookingSync::Engine.embedded

    last_visit = session[:_bookingsync_last_visit]
    session[:_bookingsync_last_visit] = Time.now.to_i

    if last_visit && (Time.now.to_i - last_visit > BookingSync::Engine.sign_out_after)
      clear_authorization!
    end
  end

  # Safari ignores cookies in iframes until the user clicks within them.
  #
  # This fix shows a button when the user first opens the app in an iframe,
  # which tells safari to load the app's cookies. Then the normal OAuth
  # process can continue.
  def safari_iframe_cookie_fix
    if request.user_agent =~ /Safari/
      return if session[:safari_iframe_cookie_fixed]

      if params[:safari_iframe_cookie_fix].present?
        session[:safari_iframe_cookie_fixed] = true
      else
        allow_bookingsync_iframe
        render "sessions/safari_iframe_cookie_fix", layout: "application",
          locals: {bookingsync_account_id: params[:_bookingsync_account_id]}
      end
    end
  end
end
