require "spec_helper"

RSpec.describe Application, type: :model do
  let!(:application) do
    Application.create(host: "test.host", client_id: "abc", client_secret: "def")
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:host) }
    it { is_expected.to validate_presence_of(:host) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_secret) }
    it { is_expected.to validate_presence_of(:client_secret) }
  end
end
