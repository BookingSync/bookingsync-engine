require 'spec_helper'

RSpec.describe Account, type: :model do
  shared_examples "it takes attributes from auth" do
    it "sets name" do
      expect(account.name).to eq "business name"
    end

    it "sets token" do
      expect(account.oauth_access_token).to eql("token")
      expect(account.oauth_refresh_token).to eql("refresh token")
      expect(account.oauth_expires_at).to eql("expires at")
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:uid) }
  end

  describe ".from_omniauth" do
    before { Account.create!(provider: "bookingsync", uid: 456) }

    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    context "when account exists" do
      let!(:account) { Account.create!(provider: "bookingsync", uid: 123) }

      it "loads the existing account" do
        expect(Account.from_omniauth(auth)).to eql(account)
      end

      describe "the updated account" do
        before do
          Account.from_omniauth(auth)
          account.reload
        end

        it_behaves_like "it takes attributes from auth"
      end
    end

    context "when account doesn't exist" do
      it "creates new account" do
        expect {
          Account.from_omniauth(auth)
        }.to change { Account.count }.by(1)
      end

      describe "the newly created account" do
        let!(:account) { Account.from_omniauth(auth) }

        it "sets uid and provider from auth" do
          expect(account.uid).to eq 123
          expect(account.provider).to eq "bookingsync"
        end

        it_behaves_like "it takes attributes from auth"
      end
    end
  end

  describe "#token" do
    let(:expires_at) { 1.day.from_now.to_i }
    let(:account) { Account.create!(uid: 123, oauth_access_token: "token",
      oauth_refresh_token: "refresh_token", oauth_expires_at: expires_at) }

    context "when the stored token is fresh" do
      it "returns the token" do
        expect(account.token).to be_a OAuth2::AccessToken
        expect(account.token.token).to eq "token"
      end
    end

    context "when the stored token is expired" do
      self.use_transactional_fixtures = false

      let(:expires_at) { 1.day.ago.to_i.to_s }
      let(:new_expires_at) { 2.days.from_now.to_i.to_s }
      let(:token) { double(expired?: true, refresh!: double(token: "refreshed_token",
        refresh_token: "refreshed_refresh_token", expires_at: new_expires_at)) }
      let(:client) { double }

      before do
        expect(BookingSync::Engine).to receive(:oauth_client) { client }
        expect(OAuth2::AccessToken).to receive(:new).with(client, "token",
          refresh_token: "refresh_token", expires_at: expires_at) { token }
      end

      it "refreshes the token" do
        expect(token).to receive(:refresh!)
        account.token
      end

      it "stores the refreshed token" do
        account.token
        account.reload
        expect(account.oauth_access_token).to eq("refreshed_token")
        expect(account.oauth_refresh_token).to eq("refreshed_refresh_token")
        expect(account.oauth_expires_at).to eq(new_expires_at)
      end

      after do
        Account.destroy_all
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
