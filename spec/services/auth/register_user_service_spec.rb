require "rails_helper"

RSpec.describe Auth::RegisterUserService do
  let(:organization) { create(:organization) }
  let(:valid_params) do
    {
      name:     "John Doe",
      email:    "john@example.com",
      password: "password123",
      phone:    "+5511999999999"
    }
  end

  describe "#call" do
    context "with valid params" do
      it "creates a user" do
        expect {
          described_class.new(valid_params, organization).call
        }.to change(User, :count).by(1)
      end

      it "returns success: true" do
        result = described_class.new(valid_params, organization).call
        expect(result[:success]).to be true
      end

      it "returns the created user" do
        result = described_class.new(valid_params, organization).call
        expect(result[:user]).to be_a(User)
        expect(result[:user].email).to eq("john@example.com")
      end

      it "returns a JWT token" do
        result = described_class.new(valid_params, organization).call
        expect(result[:token]).to be_present
      end

      it "encodes user_id and organization_id in the token" do
        result = described_class.new(valid_params, organization).call
        payload = JsonWebToken.decode(result[:token])
        expect(payload["user_id"]).to eq(result[:user].id)
        expect(payload["organization_id"]).to eq(organization.id)
      end

      it "assigns participant role by default" do
        result = described_class.new(valid_params, organization).call
        expect(result[:user].role).to eq("participant")
      end

      it "scopes user to the organization" do
        result = described_class.new(valid_params, organization).call
        expect(result[:user].organization).to eq(organization)
      end
    end

    context "with duplicate email in same organization" do
      before { create(:user, organization: organization, email: "john@example.com") }

      it "does not create a user" do
        expect {
          described_class.new(valid_params, organization).call
        }.not_to change(User, :count)
      end

      it "returns success: false with errors" do
        result = described_class.new(valid_params, organization).call
        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end

    context "with same email in different organization" do
      let(:other_org) { create(:organization) }

      before { create(:user, organization: other_org, email: "john@example.com") }

      it "creates the user successfully" do
        result = described_class.new(valid_params, organization).call
        expect(result[:success]).to be true
      end
    end

    context "with missing required params" do
      it "returns error when name is blank" do
        result = described_class.new(valid_params.merge(name: ""), organization).call
        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end

      it "returns error when password is too short" do
        result = described_class.new(valid_params.merge(password: "short"), organization).call
        expect(result[:success]).to be false
      end
    end
  end
end
