class BookingSync::Engine::CredentialsResolver
  attr_accessor :host

  def initialize(host)
    @host = host
  end

  def call
    if application = ::Application.find_by_host(host)
      {
        client_id: application.client_id,
        client_secret: application.client_secret
      }
    else
      nil
    end
  end
end
