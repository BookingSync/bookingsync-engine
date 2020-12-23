module BookingSyncEngine
  cattr_accessor :support_multi_applications
  self.support_multi_applications = false

  cattr_accessor :single_app_model
  self.single_app_model = -> { ::Account }

  cattr_accessor :multi_app_model
  self.multi_app_model = -> { ::Account }

  cattr_accessor :oauth_client_connection_options
  self.oauth_client_connection_options = { request: { timeout: 2 } }

  cattr_accessor :token_refresh_timeout_retry_count
  self.token_refresh_timeout_retry_count = 2

  def self.setup
    yield self
  end

  def self.support_multi_applications?
    support_multi_applications
  end

  def self.account_model
    support_multi_applications? ? multi_app_model.call : single_app_model.call
  end
end

require "bookingsync"
