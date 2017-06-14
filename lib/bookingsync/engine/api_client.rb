class BookingSync::Engine::APIClient < BookingSync::API::Client
  def initialize(token, options = {})
    super
    @account = options[:account]
  end

  def call(method, path, data = nil, options = nil)
    tries ||= 1
    super
  rescue BookingSync::API::Unauthorized => error
    if refresh_token?(error) && (tries -= 1) >= 0
      @token = @account.refresh_token!.token
      retry
    else
      raise
    end
  end

  private

  def refresh_token?(error)
    error.headers["www-authenticate"].include?("The access token expired")
  end
end
