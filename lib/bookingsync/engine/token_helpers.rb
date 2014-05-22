module BookingSync::Engine::TokenHelpers
  extend ActiveSupport::Concern

  private

  # OAuth access token for the current account. Will refresh the token
  # if it's expired and store the new token in the database.
  #
  # @return [OAuth2::AccessToken] access token for current account
  def current_account_token
    current_account.token
  end

  # OAuth access token for the application. The token is obtained from
  # {BookingSync::Engine#appliation_token}.
  #
  # Will fetch new token if the current one is expired.
  #
  # The token is stored in thread local storage, to reduce the amount of
  # token requests.
  #
  # @return [OAuth2::AccessToken] access token for application
  def application_token
    token = Thread.current[:_bookingsync_application_token]
    if token.nil? || token.expired?
      token = Thread.current[:_bookingsync_application_token] =
        BookingSync::Engine.application_token
    end
    token
  end
end
