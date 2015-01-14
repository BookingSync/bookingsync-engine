require 'spec_helper'

RSpec.describe SessionsController, type: :controller do
  describe "GET create" do
    before do
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:bookingsync]
    end

    it "loads or creates account from omniauth auth" do
      expect(Account).to receive(:from_omniauth).and_call_original
      get :create, provider: :bookingsync, use_route: 'bookingsync'
    end

    it "runs the account_authorized callback" do
      expect(controller).to receive(:account_authorized)
      get :create, provider: :bookingsync, use_route: 'bookingsync'
    end

    it "redirects to after_bookingsync_sign_in_path" do
      expect(controller).to receive(:after_bookingsync_sign_in_path).and_return("/admin")
      get :create, provider: :bookingsync, use_route: 'bookingsync'
      expect(response).to redirect_to("/admin")
    end
  end

  describe "GET destroy" do
    it "clears authorization" do
      expect(controller).to receive(:clear_authorization!)
      get :destroy, use_route: 'bookingsync'
    end

    it "redirects to after_bookingsync_sign_out_path" do
      expect(controller).to receive(:after_bookingsync_sign_out_path).and_return("/signed_out")
      get :destroy, use_route: 'bookingsync'
      expect(response).to redirect_to("/signed_out")
    end
  end

  describe "GET failure" do
    context "when Engine is embedded" do
      before { BookingSync::Engine.embedded! }
      it "clears X-Frame-Options" do
        get :failure, use_route: 'bookingsync'
        expect(response.headers["X-Frame-Options"]).to eql("")
      end
    end

    context "when Engine is standalone" do
      before { BookingSync::Engine.standalone! }

      it "leaves X-Frame-Options without change" do
        get :failure, use_route: 'bookingsync'
        expect(response.headers["X-Frame-Options"]).to eql("SAMEORIGIN")
      end
    end
  end
end
