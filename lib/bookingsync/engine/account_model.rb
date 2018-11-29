class BookingsyncEngineUniquenessValidator < ActiveRecord::Validations::UniquenessValidator
  def initialize(options)
    if options[:scope].present? && options[:scope].respond_to?(:call)
      options[:scope] = options[:scope].call
    end
    super
  end
end

module BookingSync::Engine::AccountModel
  extend ActiveSupport::Concern

  included do
    validates :synced_id, bookingsync_engine_uniqueness: {
      scope: Proc.new { BookingSync::Engine.support_multi_applications? ? :host : nil }
    }
    scope :authorized, -> { where.not(oauth_access_token: nil) }
  end

  module ClassMethods
    def from_omniauth(auth, host: nil)
      if BookingSync::Engine.support_multi_applications?
        if host.present?
          account = find_or_initialize_by(host: host, synced_id: auth.uid, provider: auth.provider)
        else
          raise ArgumentError, "The `host` variable must be passed when using BookingSync Engine with " \
                               "multi application support"
        end
      else
        account = find_or_initialize_by(synced_id: auth.uid, provider: auth.provider)
      end

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end
  end

  def token
    @token ||= begin
      token_options = {}
      if oauth_refresh_token
        token_options[:refresh_token] = oauth_refresh_token
        token_options[:expires_at]    = oauth_expires_at
      end

      token = OAuth2::AccessToken.new(oauth_client, oauth_access_token, token_options)

      if token.expired?
        refresh_token!(token)
      else
        token
      end
    end
  end

  def application_token
    if BookingSync::Engine.support_multi_applications?
      BookingSync::Engine.application_token(
        client_id: application.client_id,
        client_secret: application.client_secret
      )
    else
      BookingSync::Engine.application_token
    end
  end

  def oauth_client
    if BookingSync::Engine.support_multi_applications?
      BookingSync::Engine.oauth_client(
        client_id: application.client_id,
        client_secret: application.client_secret
      )
    else
      BookingSync::Engine.oauth_client
    end
  end

  def application
    if BookingSync::Engine.support_multi_applications?
      @application ||= Application.find_by_host(host)
    else
      nil
    end
  end

  def refresh_token!(current_token = token)
    @token = current_token.refresh!.tap { |new_token| update_token!(new_token) }
  end

  def api
    @api ||= BookingSync::Engine::APIClient.new(token.token, account: self)
  end

  def update_token(token)
    self.oauth_access_token   = token.token
    self.oauth_refresh_token  = token.refresh_token
    self.oauth_expires_at     = token.expires_at
  end

  def update_token!(token)
    update_token(token)
    save!
  end

  def clear_token!
    self.oauth_access_token   = nil
    self.oauth_refresh_token  = nil
    self.oauth_expires_at     = nil
    save!
  end
end
