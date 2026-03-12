require "rails_helper"

RSpec.describe SuperAdmin::CreateOrganizationService do
  subject(:service) { described_class.new(params) }

  describe "#call" do
    context "with valid params" do
      let(:params) { { name: "Acme Corp", slug: "acme-corp", owner_email: "owner@acme.com" } }

      it "returns success" do
        result = service.call
        expect(result[:success]).to be true
      end

      it "creates the organization" do
        expect { service.call }.to change(Organization, :count).by(1)
      end

      it "sets correct attributes" do
        result = service.call
        org = result[:organization]
        expect(org.name).to eq("Acme Corp")
        expect(org.slug).to eq("acme-corp")
        expect(org.owner_email).to eq("owner@acme.com")
        expect(org.status).to eq("pending")
      end
    end

    context "with optional status" do
      let(:params) { { name: "Acme Corp", slug: "acme-corp", owner_email: "owner@acme.com", status: "active" } }

      it "sets the given status" do
        result = service.call
        expect(result[:organization].status).to eq("active")
      end
    end

    context "with invalid params" do
      let(:params) { { name: "", slug: "invalid slug!", owner_email: "not-email" } }

      it "returns failure" do
        result = service.call
        expect(result[:success]).to be false
      end

      it "returns errors" do
        result = service.call
        expect(result[:errors]).to be_present
      end

      it "does not create the organization" do
        expect { service.call }.not_to change(Organization, :count)
      end
    end

    context "with duplicate slug" do
      before { create(:organization, slug: "taken") }
      let(:params) { { name: "Other", slug: "taken", owner_email: "other@example.com" } }

      it "returns failure" do
        result = service.call
        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end
  end
end
