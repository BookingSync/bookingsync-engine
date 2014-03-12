OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:bookingsync] = OmniAuth::AuthHash.new({
  provider: "bookingsync",
  uid: 123,
  info: {
    business_name: "business name"
  },
  credentials: {
    token: "token",
    refresh_token: "refresh token",
    expires_at: "expires at"
  }
})
