require "swagger_helper"

RSpec.describe "api/v1/auth", type: :request do
  let(:organization) { create(:organization) }

  path "/api/v1/auth/register" do
    post "Register a new user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: "X-Organization-Id", in: :header, type: :string, required: true,
                description: "Organization ID"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name:     { type: :string, example: "John Doe" },
          email:    { type: :string, example: "john@example.com" },
          password: { type: :string, example: "password123" },
          phone:    { type: :string, example: "+5511999999999" }
        },
        required: [ "name", "email", "password" ]
      }

      response "201", "user registered" do
        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { name: "John Doe", email: "john@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["token"]).to be_present
          expect(data["user"]["email"]).to eq("john@example.com")
          expect(data["user"]["role"]).to eq("participant")
        end
      end

      response "422", "invalid params" do
        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { name: "", email: "invalid", password: "short" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "404", "organization not found" do
        let("X-Organization-Id") { "0" }
        let(:body) { { name: "John Doe", email: "john@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Organization not found")
        end
      end

      response "422", "duplicate email in same organization" do
        before { create(:user, organization: organization, email: "john@example.com") }

        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { name: "John Doe", email: "john@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Login" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: "X-Organization-Id", in: :header, type: :string, required: true,
                description: "Organization ID"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email:    { type: :string, example: "john@example.com" },
          password: { type: :string, example: "password123" }
        },
        required: [ "email", "password" ]
      }

      response "200", "login successful" do
        let!(:user) { create(:user, organization: organization, email: "john@example.com", password: "password123") }
        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { email: "john@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["token"]).to be_present
          expect(data["user"]["email"]).to eq("john@example.com")
        end
      end

      response "401", "invalid credentials" do
        let!(:user) { create(:user, organization: organization, email: "john@example.com", password: "password123") }
        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { email: "john@example.com", password: "wrongpassword" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "401", "user from another organization" do
        let(:other_org) { create(:organization) }
        let!(:user) { create(:user, organization: other_org, email: "john@example.com", password: "password123") }
        let("X-Organization-Id") { organization.id.to_s }
        let(:body) { { email: "john@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "404", "organization not found" do
        let("X-Organization-Id") { "0" }
        let(:body) { { email: "john@example.com", password: "password123" } }

        run_test!
      end
    end
  end
end

RSpec.describe "api/v1/auth — super_admin", type: :request do
  describe "POST /api/v1/auth/login without X-Organization-Id" do
    let!(:super_admin) { create(:user, :super_admin, email: "sa@platform.com", password: "password123") }

    it "returns 200 with valid super_admin credentials" do
      post "/api/v1/auth/login",
           params: { email: "sa@platform.com", password: "password123" }.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["token"]).to be_present
      expect(data["user"]["role"]).to eq("super_admin")
    end

    it "returns 401 with wrong password" do
      post "/api/v1/auth/login",
           params: { email: "sa@platform.com", password: "wrong" }.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      data = JSON.parse(response.body)
      expect(data["errors"]).to be_present
    end

    it "returns 401 when regular user tries to login without org header" do
      org  = create(:organization)
      create(:user, organization: org, email: "regular@example.com", password: "password123")

      post "/api/v1/auth/login",
           params: { email: "regular@example.com", password: "password123" }.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/register without X-Organization-Id" do
    it "returns 404" do
      post "/api/v1/auth/register",
           params: { name: "John", email: "john@example.com", password: "password123" }.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:not_found)
      data = JSON.parse(response.body)
      expect(data["error"]).to eq("Organization not found")
    end
  end
end
