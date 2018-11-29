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
    context "without multi applications support" do
      it { is_expected.to validate_uniqueness_of(:synced_id) }
    end

    context "with multi applications support" do
      before do
        # TODO: Need to find a way to force this variable before the spec test run and the app code initialized
        # ENV['BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS'] = "true"
      end

      it { is_expected.to validate_uniqueness_of(:synced_id).scoped_to(:host) }
    end
  end

  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    context "without multi applications support" do
      before { Account.create!(provider: "bookingsync", synced_id: 456) }
  
      context "when account exists" do
        let!(:account) { Account.create!(provider: "bookingsync", synced_id: 123) }
  
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
  
          it "sets synced_id and provider from auth" do
            expect(account.synced_id).to eq 123
            expect(account.provider).to eq "bookingsync"
          end
  
          it_behaves_like "it takes attributes from auth"
        end
      end
    end

    context "with multi applications support" do
      before do
        # TODO: Need to find a way to force this variable before the spec test run and the app code initialized
        # ENV['BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS'] = "true"
        Account.create!(provider: "bookingsync", synced_id: 456, host: "test.example")
        Account.create!(provider: "bookingsync", synced_id: 456, host: "test2.example")
      end
  
      let!(:account) { Account.create!(provider: "bookingsync", synced_id: 123, host: "test.example") }

      context "without host given" do
        it "raises an error" do
          expect { Account.from_omniauth(auth) }.to raise_error(ArgumentError,
            "The `host` variable must be passed when using BookingSync Engine with multi application support")
        end
      end

      context "with host given" do
        context "when account exists" do
          it "loads the existing account" do
            expect(Account.from_omniauth(auth, host: "test.example")).to eql(account)
          end
    
          describe "the updated account" do
            before do
              Account.from_omniauth(auth, host: "test.example")
              account.reload
            end
    
            it_behaves_like "it takes attributes from auth"
          end
        end
    
        context "when account doesn't exist" do
          it "creates new account" do
            expect {
              Account.from_omniauth(auth, host: "test2.example")
            }.to change { Account.count }.by(1)
          end
    
          describe "the newly created account" do
            let!(:account) { Account.from_omniauth(auth, host: "test2.example") }
    
            it "sets synced_id and provider from auth as well as host" do
              expect(account.synced_id).to eq 123
              expect(account.provider).to eq "bookingsync"
              expect(account.host).to eq "test2.example"
            end
    
            it_behaves_like "it takes attributes from auth"
          end
        end
      end
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

    context "without multi application support" do
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

    context "with multi application support" do
      let!(:account) { Account.create!(synced_id: 123, host: "test.example") }
      let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

      before do
        # TODO: Need to find a way to force this variable before the spec test run and the app code initialized
        # ENV['BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS'] = "true"
      end

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
  end

  describe "#oauth_client" do
    context "without multi application support" do
      let!(:account) { Account.create!(synced_id: 123) }

      it "returns a BookingSync::Engine.oauth_client setup without default params" do
        expect(BookingSync::Engine).to receive(:oauth_client).with(no_args).and_call_original
        expect(account.oauth_client).to be_an OAuth2::Client
      end
    end

    context "with multi application support" do
      let!(:account) { Account.create!(synced_id: 123, host: "test.example") }
      let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

      before do
        # TODO: Need to find a way to force this variable before the spec test run and the app code initialized
        # ENV['BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS'] = "true"
      end

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
  end

  describe "#application" do
    let!(:account) { Account.create!(synced_id: 123, host: "test.example") }

    context "without multi application support" do
      it "returns nil" do
        expect(account.application).to be_nil
      end
    end

    context "with multi application support" do
      let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }
      let!(:application2) { Application.create!(host: "test2.example", client_id: "234", client_secret: "567") }

      before do
        # TODO: Need to find a way to force this variable before the spec test run and the app code initialized
        # ENV['BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS'] = "true"
      end

      it "returns the application matching the host" do
        expect(account.application).to eq application
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
end
