require 'spec_helper'

RSpec.describe SessionsController, type: :controller do
  routes { BookingSync::Engine.routes }

  describe "GET create" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    before do
      request.env["omniauth.auth"] = auth
    end

    context "with single app setup" do
      before do
        allow(BookingSyncEngine).to receive(:support_multi_applications?).and_return(false)
      end

      it "loads or creates account from omniauth auth" do
        expect {
          get :create, params: { provider: :bookingsync }
        }.to change { Account.count }.by(1)
        expect(Account.last.synced_id).to eq(123)
      end
    end

    context "with multi app setup" do
      before do
        allow(BookingSyncEngine).to receive(:support_multi_applications?).and_return(true)
      end

      it "loads or creates account from omniauth auth" do
        expect {
          get :create, params: { provider: :bookingsync }
        }.to change { MultiApplicationsAccount.count }.by(1)
        expect(MultiApplicationsAccount.last.synced_id).to eq(123)
        expect(MultiApplicationsAccount.last.host).to eq("test.host")
      end
    end

    it "runs the account_authorized callback" do
      expect(controller).to receive(:account_authorized)
      get :create, params: { provider: :bookingsync }
    end

    it "redirects to after_bookingsync_sign_in_path" do
      expect(controller).to receive(:after_bookingsync_sign_in_path).and_return("/admin")
      get :create, params: { provider: :bookingsync }
      expect(response).to redirect_to("/admin")
    end
  end

  describe "GET destroy" do
    it "clears authorization" do
      expect(controller).to receive(:clear_authorization!)
      get :destroy
    end

    it "redirects to after_bookingsync_sign_out_path" do
      expect(controller).to receive(:after_bookingsync_sign_out_path).and_return("/signed_out")
      get :destroy
      expect(response).to redirect_to("/signed_out")
    end
  end

  describe "GET failure" do
    context "when Engine is embedded" do
      before { BookingSync::Engine.embedded! }
      it "clears X-Frame-Options" do
        get :failure
        expect(response.headers["X-Frame-Options"]).to eql("")
      end
    end

    context "when Engine is standalone" do
      before { BookingSync::Engine.standalone! }

      it "leaves X-Frame-Options without change" do
        get :failure
        expect(response.headers["X-Frame-Options"]).to eql("SAMEORIGIN")
      end
    end
  end
end
