# General helpers related to integrating applications with BookingSync
module BookingSync::Engine::Helpers
  extend ActiveSupport::Concern

  private

  # Clears the X-Frame-Options header so that the application can be embedded
  # in an iframe. This is required for loading applications in the
  # BookingSync app store.
  #
  # This should set ALLOW-FROM, but it's not supported in Chrome and Safari.
  def allow_bookingsync_iframe
    response.headers['X-Frame-Options'] = '' if ::BookingSync::Engine.embedded
  end
end
