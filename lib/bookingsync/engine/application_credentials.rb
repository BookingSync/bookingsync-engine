class BookingSync::Engine::ApplicationCredentials
  attr_reader :client_id
  attr_reader :client_secret

  def initialize(application = nil)
    if application.present?
      @client_id = application.client_id
      @client_secret = application.client_secret
    end
  end

  def valid?
    client_id.present? && client_secret.present?
  end
end
