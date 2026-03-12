require "swagger_helper"

RSpec.describe "api/v1/organization", type: :request do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:token) { JsonWebToken.encode({ user_id: admin.id, organization_id: organization.id }) }
  let(:Authorization) { "Bearer #{token}" }

  before do
    allow(ImageProcessor).to receive(:call).and_return(
      StringIO.new("fake-webp-content")
    )
  end

  path "/api/v1/organization/update_logo" do
    put "Upload organization logo" do
      tags "Organization"
      consumes "multipart/form-data"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :logo, in: :formData, type: :file, required: true,
                description: "Logo image file (will be converted to webp)"

      response "200", "logo uploaded" do
        let(:logo) { fixture_file_upload(Rails.root.join("spec/fixtures/files/logo.png"), "image/png") }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["logo_url"]).to be_present
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:logo) { fixture_file_upload(Rails.root.join("spec/fixtures/files/logo.png"), "image/png") }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end

      response "403", "forbidden (not admin)" do
        let(:participant) { create(:user, organization: organization) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: participant.id, organization_id: organization.id })}" }
        let(:logo) { fixture_file_upload(Rails.root.join("spec/fixtures/files/logo.png"), "image/png") }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end

      response "422", "no file provided" do
        let(:logo) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("No file provided")
        end
      end
    end
  end

  path "/api/v1/organization/destroy_logo" do
    delete "Remove organization logo" do
      tags "Organization"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      response "204", "logo removed" do
        before { organization.logo.attach(io: StringIO.new("fake"), filename: "logo.webp", content_type: "image/webp") }

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end

      response "403", "forbidden (not admin)" do
        let(:participant) { create(:user, organization: organization) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: participant.id, organization_id: organization.id })}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end
    end
  end
end
