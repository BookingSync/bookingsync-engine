class Bookingsync::Engine::APIClient < BookingSync::API::Client
  def initialize(token, options = {})
    super
    @account = options[:account]
  end

  def call(method, path, data = nil, options = nil)
    tries ||= 1
    super
  rescue BookingSync::API::Unauthorized => e
    token_expired = e.headers["www-authenticate"].include?("The access token expired")
    if token_expired && (tries -= 1) >= 0
      @token = @account.refresh_token!.token
      retry
    else
      raise
    end
  end
end
