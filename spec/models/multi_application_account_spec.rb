require "spec_helper"

RSpec.describe MultiApplicationsAccount, type: :model do
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
    let!(:account) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 123, host: "example.test")
    end

    it { is_expected.to validate_uniqueness_of(:synced_id).scoped_to(:host).case_insensitive }
  end

  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }
    let!(:account) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 123, host: "example.test")
    end
    let!(:account2) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 456, host: "example2.test")
    end

    context "without host given" do
      it "raises an error" do
        expect { MultiApplicationsAccount.from_omniauth(auth, nil) }.to raise_error(ArgumentError,
          "The `host` variable must be passed when using BookingSync Engine with multi application support")
      end
    end

    context "with host given" do
      context "when account exists" do
        it "loads the existing account" do
          expect(MultiApplicationsAccount.from_omniauth(auth, "example.test")).to eql(account)
        end
    
        describe "the updated account" do
          before do
            MultiApplicationsAccount.from_omniauth(auth, "example.test")
            account.reload
          end
    
          it_behaves_like "it takes attributes from auth"
        end
      end
    
      context "when account doesn't exist" do
        it "creates new account" do
          expect {
            MultiApplicationsAccount.from_omniauth(auth, "example3.test")
          }.to change { MultiApplicationsAccount.count }.by(1)
        end
    
        describe "the newly created account" do
          let!(:account) { MultiApplicationsAccount.from_omniauth(auth, "example3.test") }
    
          it "sets synced_id and provider from auth as well as host" do
            expect(account.synced_id).to eq 123
            expect(account.provider).to eq "bookingsync"
            expect(account.host).to eq "example3.test"
          end
    
          it_behaves_like "it takes attributes from auth"
        end
      end
    end
  end

  describe "#token" do
    let(:expires_at) { 1.day.from_now.to_i }
    let!(:account) do
      MultiApplicationsAccount.create!(synced_id: 123, oauth_access_token: "token",
        oauth_refresh_token: "refresh_token", oauth_expires_at: expires_at, host: "example.test")
    end
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
      if rails_version >=5
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
        MultiApplicationsAccount.destroy_all
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

    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

    it "returns a client credential token setup with application's credentials" do
      expect(client_credentials).to receive(:get_token).and_return("client_credentials_token")
      expect(oauth2_client).to receive(:client_credentials).and_return(client_credentials)
      expect(OAuth2::Client).to receive(:new)
        .with(application.client_id, application.client_secret, any_args)
        .and_return(oauth2_client)

      expect(BookingSync::Engine).to receive(:application_token)
        .with(client_id: application.client_id, client_secret: application.client_secret)
        .at_least(1)
        .and_call_original
      expect(account.application_token).to eq "client_credentials_token"
    end
  end

  describe "#oauth_client" do
    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

    it "returns a BookingSync::Engine.oauth_client setup with application's credentials" do
      expect(BookingSync::Engine).to receive(:oauth_client)
        .with(client_id: application.client_id, client_secret: application.client_secret)
        .at_least(1)
        .and_call_original
      expect(account.oauth_client).to be_an OAuth2::Client
      expect(account.oauth_client.id).to eq application.client_id
      expect(account.oauth_client.secret).to eq application.client_secret
    end
  end

  describe "#application" do
    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }
    let!(:application2) { Application.create!(host: "test2.example", client_id: "234", client_secret: "567") }

    it "returns the application matching the host" do
      expect(account.application).to eq application
    end
  end

  describe "#api" do
    let!(:account) { MultiApplicationsAccount.new }
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
      account = MultiApplicationsAccount.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires", host: "example.test")

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

  describe ".find_by_host_and_synced_id" do
    let!(:account_1) { MultiApplicationsAccount.create!(synced_id: 1, host: "example.test") }
    let!(:account_2) { MultiApplicationsAccount.create!(synced_id: 2, host: "example.test") }
    let!(:account_3) { MultiApplicationsAccount.create!(synced_id: 1, host: "example2.test") }
    let!(:account_4) { MultiApplicationsAccount.create!(synced_id: 2, host: "example2.test") }

    it "returns the right account" do
      expect(MultiApplicationsAccount.find_by_host_and_synced_id("example2.test", 1)).to eq account_3
    end
  end
end
