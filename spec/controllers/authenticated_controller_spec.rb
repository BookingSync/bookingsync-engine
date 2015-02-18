require 'spec_helper'

RSpec.describe AuthenticatedController, type: :controller do
  describe "GET index" do
    context "when engine is embedded" do
      before { Bookingsync::Engine.embedded! }

      it "redirects to auth using js" do
        get :index
        expect(response.status).to eq(200)
        expect(response.body).to eq(
          "<script type='text/javascript'>top.location.href = '/auth/bookingsync/?account_id=';</script>")
      end
    end

    context "when engine is standalone" do
      before { Bookingsync::Engine.standalone! }

      it "redirects to auth using 302 redirect" do
        get :index
        expect(response.status).to eq(302)
        expect(response.redirect_url).to eq("http://test.host/auth/bookingsync/?account_id=")
        expect(response.body).to eq(
          "<html><body>You are being <a href=\"http://test.host/auth/bookingsync/?account_id=\">redirected</a>.</body></html>")
      end
    end
  end

  describe "XHR index" do
    context "when engine is embedded" do
      before { Bookingsync::Engine.embedded! }

      it "renders the target url in response" do
        xhr :get, :index
        expect(response.status).to eq(401)
        expect(response.body).to eq("http://test.host/auth/bookingsync/?account_id=")
      end
    end

    context "when engine is standalone" do
      before { Bookingsync::Engine.standalone! }

      it "renders the target url in response" do
        xhr :get, :index
        expect(response.status).to eq(401)
        expect(response.body).to eq("http://test.host/auth/bookingsync/?account_id=")
      end
    end
  end
end
