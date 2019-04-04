require "spec_helper"

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
    it { is_expected.to validate_uniqueness_of(:synced_id) }
  end

  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    before { Account.create!(provider: "bookingsync", synced_id: 456) }

    context "when account exists" do
      let!(:account) { Account.create!(provider: "bookingsync", synced_id: 123) }

      context "with host given" do
        it "loads the existing account" do
          expect(Account.from_omniauth(auth, "example.test")).to eql(account)
        end
      end

      context "without host given" do
        it "loads the existing account" do
          expect(Account.from_omniauth(auth, nil)).to eql(account)
        end
      end

      describe "the updated account" do
        before do
          Account.from_omniauth(auth, "example.test")
          account.reload
        end

        it_behaves_like "it takes attributes from auth"
      end
    end

    context "when account doesn't exist" do
      it "creates new account" do
        expect {
          Account.from_omniauth(auth, "example.test")
        }.to change { Account.count }.by(1)
      end

      describe "the newly created account" do
        let!(:account) { Account.from_omniauth(auth, "example.test") }

        it "sets synced_id and provider from auth" do
          expect(account.synced_id).to eq 123
          expect(account.provider).to eq "bookingsync"
        end

        it_behaves_like "it takes attributes from auth"
      end
    end
  end

  describe ".find_by_host_and_synced_id" do
    let!(:account_1) { Account.create!(synced_id: 1) }
    let!(:account_2) { Account.create!(synced_id: 2) }
    let!(:account_3) { Account.create!(synced_id: 3) }

    it "returns the right account" do
      expect(Account.find_by_host_and_synced_id("any_host", 3)).to eq account_3
    end
  end

  describe "#token" do
    let(:expires_at) { 1.day.from_now.to_i }
    let!(:account) { Account.create!(synced_id: 123, oauth_access_token: "token",
      oauth_refresh_token: "refresh_token", oauth_expires_at: expires_at) }
    let(:oauth_client) { double }

    before do
      allow(account).to receive(:oauth_client).with(no_args).and_return(oauth_client)
    end

    context "when the stored token is fresh" do
      it "returns the token" do
        expect(account.token).to be_a OAuth2::AccessToken
        expect(account.token.token).to eq "token"
      end
    end

    context "when the stored token is expired" do
      # comparing rails version, the use_transactional_fixtures only works pre 5
      if Rails::VERSION::STRING.split(".").first.to_i >=5
        self.use_transactional_tests = false
      else
        self.use_transactional_fixtures = false
      end

      let(:expires_at) { 1.day.ago.to_i.to_s }
      let(:new_expires_at) { 2.days.from_now.to_i.to_s }
      let(:token) do
        double(expired?: true, refresh!: double(token: "refreshed_token",
          refresh_token: "refreshed_refresh_token", expires_at: new_expires_at))
      end

      before do
        expect(OAuth2::AccessToken).to receive(:new).with(oauth_client, "token",
          refresh_token: "refresh_token", expires_at: expires_at) { token }
      end

      after do
        Account.destroy_all
      end

      it "refreshes the token" do
        expect(token).to receive(:refresh!)
        account.token
      end
    end
  end

  describe "#application_token" do
    let(:client_credentials) { double }
    let(:oauth2_client) { double }
    let!(:account) { Account.create!(synced_id: 123) }

    it "returns a client credential token setup without default params" do
      expect(client_credentials).to receive(:get_token).and_return("client_credentials_token")
      expect(oauth2_client).to receive(:client_credentials).and_return(client_credentials)
      expect(OAuth2::Client).to receive(:new)
        .with(ENV['BOOKINGSYNC_APP_ID'], ENV['BOOKINGSYNC_APP_SECRET'], any_args)
        .and_return(oauth2_client)

      expect(BookingSync::Engine).to receive(:application_token)
        .with(no_args).at_least(1).and_call_original
      expect(account.application_token).to eq "client_credentials_token"
    end
  end

  describe "#oauth_client" do
    let!(:account) { Account.create!(synced_id: 123) }

    it "returns a BookingSync::Engine.oauth_client setup without default params" do
      expect(BookingSync::Engine).to receive(:oauth_client).with(no_args).and_call_original
      expect(account.oauth_client).to be_an OAuth2::Client
    end
  end

  describe "#application" do
    let!(:account) { Account.create!(synced_id: 123) }

    it "returns nil" do
      expect(account.application).to be_nil
    end
  end

  describe "#api" do
    let!(:account) { Account.new }
    let(:oauth_client) { double }

    before do
      allow(account).to receive(:oauth_client).with(no_args).and_return(oauth_client)
    end

    it "returns API client initialized with OAuth token" do
      token = double(token: "access_token", expired?: false)
      allow(OAuth2::AccessToken).to receive(:new).and_return(token)

      expect(account.api).to be_kind_of(BookingSync::API::Client)
      expect(account.api.token).to eq("access_token")
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

  describe "#update_token" do
    it "updates the token related fields on account" do
      token = double(token: "new_access_token", refresh_token: "new_refresh_token", expires_at: "new_expires_at")
      account = MultiApplicationsAccount.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires", host: "example.test")

      account.update_token(token)

      expect(account.oauth_access_token).to eq "new_access_token"
      expect(account.oauth_refresh_token).to eq "new_refresh_token"
      expect(account.oauth_expires_at).to eq "new_expires_at"
    end
  end
end
