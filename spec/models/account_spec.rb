require 'spec_helper'

describe Account do
  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    context "when account exists" do
      let!(:account) { Account.create!(provider: "bookingsync", uid: 123) }

      it "loads the existing account" do
        expect(Account.from_omniauth(auth)).to eql(account)
      end

      it "updates account's name" do
        Account.from_omniauth(auth)
        expect(account.reload.name).to eql("business name")
      end

      it "updates account's token" do
        Account.from_omniauth(auth)
        account.reload
        expect(account.oauth_access_token).to eql("token")
        expect(account.oauth_refresh_token).to eql("refresh token")
        expect(account.oauth_expires_at).to eql("expires at")
      end
    end
  end

  describe "#clear_token!" do
    it "clears token related fields on account" do
      account = Account.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires")

      account.clear_token!
      account.reload

      expect(account.oauth_access_token).to be_nil
      expect(account.oauth_refresh_token).to be_nil
      expect(account.oauth_expires_at).to be_nil
    end
  end

  describe "#api" do
    it "returns API client initialized with OAuth token" do
      token = double(token: "access_token", expired?: false)
      allow(OAuth2::AccessToken).to receive(:new)
        .and_return(token)
      account = Account.new

      expect(account.api).to be_kind_of(BookingSync::API::Client)
      expect(account.api.token).to eq("access_token")
    end
  end
end
