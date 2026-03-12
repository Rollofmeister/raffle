require "swagger_helper"

RSpec.describe "api/v1/super_admin/organizations", type: :request do
  let(:super_admin) { create(:user, :super_admin, organization: nil) }
  let(:token)       { JsonWebToken.encode({ user_id: super_admin.id, organization_id: nil }) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/super_admin/organizations" do
    get "List all organizations" do
      tags "SuperAdmin - Organizations"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :page,  in: :query, type: :integer, required: false
      parameter name: :limit, in: :query, type: :integer, required: false

      response "200", "organizations listed" do
        before { create_list(:organization, 3) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["organizations"]).to be_an(Array)
          expect(data["organizations"].length).to eq(3)
          expect(data["meta"]).to include("page", "total")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end

      response "403", "forbidden (not super_admin)" do
        let(:org)   { create(:organization) }
        let(:admin) { create(:user, :admin, organization: org) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: admin.id, organization_id: org.id })}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end
    end

    post "Create an organization" do
      tags "SuperAdmin - Organizations"
      consumes "application/json"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name:        { type: :string, example: "Acme Corp" },
          slug:        { type: :string, example: "acme-corp" },
          owner_email: { type: :string, example: "owner@acme.com" },
          phone:       { type: :string, example: "+5511999999999" },
          status:      { type: :string, enum: %w[pending active suspended], example: "active" }
        },
        required: %w[name slug owner_email]
      }

      response "201", "organization created" do
        let(:body) { { name: "Acme Corp", slug: "acme-corp", owner_email: "owner@acme.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["organization"]["name"]).to eq("Acme Corp")
          expect(data["organization"]["slug"]).to eq("acme-corp")
          expect(data["organization"]["status"]).to eq("pending")
        end
      end

      response "422", "invalid params" do
        let(:body) { { name: "", slug: "invalid slug!", owner_email: "not-an-email" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "422", "duplicate slug" do
        before { create(:organization, slug: "taken-slug") }
        let(:body) { { name: "Other Corp", slug: "taken-slug", owner_email: "other@corp.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:body) { { name: "X", slug: "x", owner_email: "x@x.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end

      response "403", "forbidden (not super_admin)" do
        let(:org)   { create(:organization) }
        let(:admin) { create(:user, :admin, organization: org) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: admin.id, organization_id: org.id })}" }
        let(:body) { { name: "X", slug: "x", owner_email: "x@x.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end
    end
  end

  path "/api/v1/super_admin/organizations/{id}" do
    parameter name: :id, in: :path, type: :string

    get "Show an organization" do
      tags "SuperAdmin - Organizations"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      response "200", "organization found" do
        let(:org) { create(:organization) }
        let(:id)  { org.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["organization"]["id"]).to eq(org.id)
        end
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Organization not found")
        end
      end
    end

    patch "Update an organization" do
      tags "SuperAdmin - Organizations"
      consumes "application/json"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name:   { type: :string },
          status: { type: :string, enum: %w[pending active suspended] }
        }
      }

      response "200", "organization updated" do
        let(:org)  { create(:organization, name: "Old Name") }
        let(:id)   { org.id }
        let(:body) { { name: "New Name", status: "active" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["organization"]["name"]).to eq("New Name")
          expect(data["organization"]["status"]).to eq("active")
        end
      end

      response "404", "not found" do
        let(:id)   { 0 }
        let(:body) { { name: "X" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Organization not found")
        end
      end
    end

    delete "Soft-delete an organization" do
      tags "SuperAdmin - Organizations"
      security [ { bearerAuth: [] } ]

      response "204", "organization deleted" do
        let(:org) { create(:organization) }
        let(:id)  { org.id }

        run_test!
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Organization not found")
        end
      end
    end
  end
end
