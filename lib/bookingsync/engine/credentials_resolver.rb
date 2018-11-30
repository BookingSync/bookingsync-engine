class BookingSync::Engine::CredentialsResolver
  attr_reader :host
  private :host

  def initialize(host)
    @host = host
  end

  def call
    BookingSync::Engine::ApplicationCredentials.new(application)
  end

  private

  def application
    @application ||= ::Application.find_by_host(host)
  end
end
