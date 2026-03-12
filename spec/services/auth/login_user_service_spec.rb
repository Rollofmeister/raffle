require "rails_helper"

RSpec.describe Auth::LoginUserService do
  let(:organization) { create(:organization) }
  let(:password) { "password123" }
  let!(:user) { create(:user, organization: organization, email: "user@example.com", password: password) }

  describe "#call" do
    context "with valid credentials" do
      it "returns success: true" do
        result = described_class.new("user@example.com", password, organization).call
        expect(result[:success]).to be true
      end

      it "returns the user" do
        result = described_class.new("user@example.com", password, organization).call
        expect(result[:user]).to eq(user)
      end

      it "returns a JWT token" do
        result = described_class.new("user@example.com", password, organization).call
        expect(result[:token]).to be_present
      end

      it "encodes user_id and organization_id in the token" do
        result = described_class.new("user@example.com", password, organization).call
        payload = JsonWebToken.decode(result[:token])
        expect(payload["user_id"]).to eq(user.id)
        expect(payload["organization_id"]).to eq(organization.id)
      end

      it "is case-insensitive for email" do
        result = described_class.new("USER@EXAMPLE.COM", password, organization).call
        expect(result[:success]).to be true
      end
    end

    context "with wrong password" do
      it "returns success: false" do
        result = described_class.new("user@example.com", "wrongpass", organization).call
        expect(result[:success]).to be false
      end

      it "returns error message" do
        result = described_class.new("user@example.com", "wrongpass", organization).call
        expect(result[:errors]).to include("Invalid email or password")
      end
    end

    context "with unknown email" do
      it "returns success: false" do
        result = described_class.new("unknown@example.com", password, organization).call
        expect(result[:success]).to be false
      end
    end

    context "with discarded user" do
      before { user.discard }

      it "returns success: false" do
        result = described_class.new("user@example.com", password, organization).call
        expect(result[:success]).to be false
      end
    end

    context "tenant isolation" do
      let(:other_org) { create(:organization) }

      it "does not authenticate user from another organization" do
        result = described_class.new("user@example.com", password, other_org).call
        expect(result[:success]).to be false
      end
    end
  end
end
