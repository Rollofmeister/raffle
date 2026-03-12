require "swagger_helper"

RSpec.describe "api/v1/raffles", type: :request do
  let(:organization)  { create(:organization) }
  let(:lottery)       { create(:lottery) }
  let(:admin_user)    { create(:user, :admin, organization: organization) }
  let(:participant)   { create(:user, organization: organization) }
  let(:admin_token)   { JsonWebToken.encode({ user_id: admin_user.id, organization_id: organization.id }) }
  let(:participant_token) { JsonWebToken.encode({ user_id: participant.id, organization_id: organization.id }) }
  let(:Authorization) { "Bearer #{admin_token}" }

  let(:valid_raffle_body) do
    {
      title:        "Rifa de Natal",
      description:  "Concorra a prêmios incríveis",
      ticket_price: "20.00",
      draw_mode:    "centena",
      draw_date:    (Date.current + 30.days).to_s,
      lottery_id:   lottery.id
    }
  end

  path "/api/v1/raffles" do
    get "List raffles" do
      tags "Raffles"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :page,  in: :query, type: :integer, required: false
      parameter name: :limit, in: :query, type: :integer, required: false

      response "200", "admin sees all kept raffles" do
        before do
          create(:raffle, :draft, organization: organization, lottery: lottery)
          create(:raffle, :open,  organization: organization, lottery: lottery)
          create(:raffle, :closed, organization: organization, lottery: lottery)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffles"].length).to eq(3)
          expect(data["meta"]).to include("page", "total")
        end
      end

      response "200", "participant sees only open raffles" do
        let(:Authorization) { "Bearer #{participant_token}" }

        before do
          create(:raffle, :draft, organization: organization, lottery: lottery)
          create(:raffle, :open,  organization: organization, lottery: lottery)
          create(:raffle, :closed, organization: organization, lottery: lottery)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          statuses = data["raffles"].map { |r| r["status"] }
          expect(statuses).to all(eq("open"))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end
    end

    post "Create a raffle" do
      tags "Raffles"
      consumes "application/json"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title:        { type: :string },
          description:  { type: :string },
          ticket_price: { type: :string },
          draw_mode:    { type: :string, enum: %w[centena milhar dezena_de_milhar] },
          draw_date:    { type: :string, format: :date },
          lottery_id:   { type: :integer },
          raffle_prizes_attributes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                position:               { type: :integer },
                description:            { type: :string },
                lottery_prize_position: { type: :integer }
              }
            }
          }
        },
        required: %w[title ticket_price draw_mode draw_date lottery_id]
      }

      response "201", "raffle created without prizes" do
        let(:body) { valid_raffle_body }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["title"]).to eq("Rifa de Natal")
          expect(data["raffle"]["status"]).to eq("draft")
          expect(data["raffle"]["prizes"]).to eq([])
        end
      end

      response "201", "raffle created with prizes" do
        let(:body) do
          valid_raffle_body.merge(
            raffle_prizes_attributes: [
              { position: 1, description: "Notebook", lottery_prize_position: 1 },
              { position: 2, description: "R$ 500",   lottery_prize_position: 2 }
            ]
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["prizes"].length).to eq(2)
        end
      end

      response "422", "invalid params" do
        let(:body) { { title: "", ticket_price: "0", draw_mode: "centena", draw_date: "", lottery_id: lottery.id } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "422", "draw_date in the past" do
        let(:body) { valid_raffle_body.merge(draw_date: (Date.current - 1).to_s) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "403", "forbidden for participants" do
        let(:Authorization) { "Bearer #{participant_token}" }
        let(:body) { valid_raffle_body }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end
    end
  end

  path "/api/v1/raffles/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Show a raffle" do
      tags "Raffles"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      response "200", "raffle found with prizes" do
        let(:raffle) { create(:raffle, :draft, :with_prizes, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["id"]).to eq(raffle.id)
          expect(data["raffle"]["prizes"]).to be_an(Array)
          expect(data["raffle"]["prizes"].length).to eq(2)
        end
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Raffle not found")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unauthorized")
        end
      end
    end

    patch "Update a raffle" do
      tags "Raffles"
      consumes "application/json"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title:        { type: :string },
          ticket_price: { type: :string },
          draw_date:    { type: :string },
          draw_mode:    { type: :string },
          raffle_prizes_attributes: { type: :array, items: { type: :object } }
        }
      }

      response "200", "raffle updated" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:body)   { { title: "Updated Title" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["title"]).to eq("Updated Title")
        end
      end

      response "200", "add prize to raffle" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:body) do
          {
            raffle_prizes_attributes: [
              { position: 1, description: "Carro 0KM", lottery_prize_position: 1 }
            ]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["prizes"].length).to eq(1)
        end
      end

      response "200", "remove prize with _destroy" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let!(:prize) { create(:raffle_prize, raffle: raffle, position: 1) }
        let(:id)     { raffle.id }
        let(:body)   { { raffle_prizes_attributes: [ { id: prize.id, _destroy: "1" } ] } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["prizes"]).to be_empty
        end
      end

      response "200", "draw_mode silently ignored when open" do
        let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery, draw_mode: :centena) }
        let(:id)     { raffle.id }
        let(:body)   { { draw_mode: "milhar" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          # Service filters draw_mode for non-draft raffles; update succeeds but draw_mode unchanged
          expect(data["raffle"]["draw_mode"]).to eq("centena")
          expect(raffle.reload).to be_centena
        end
      end

      response "422", "cannot update closed raffle" do
        let(:raffle) { create(:raffle, :closed, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:body)   { { title: "New Title" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "403", "forbidden for participants" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:Authorization) { "Bearer #{participant_token}" }
        let(:body)   { { title: "Hacked" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end

      response "404", "not found" do
        let(:id)   { 0 }
        let(:body) { { title: "X" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Raffle not found")
        end
      end
    end

    delete "Delete a raffle (draft only)" do
      tags "Raffles"
      security [ { bearerAuth: [] } ]

      response "204", "draft raffle deleted" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do
          expect(Raffle.kept.find_by(id: raffle.id)).to be_nil
        end
      end

      response "422", "cannot delete non-draft raffle" do
        let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "403", "forbidden for participants" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:Authorization) { "Bearer #{participant_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Raffle not found")
        end
      end
    end
  end

  path "/api/v1/raffles/{id}/open" do
    parameter name: :id, in: :path, type: :integer

    post "Open a raffle (draft → open)" do
      tags "Raffles"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      response "200", "raffle opened" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["status"]).to eq("open")
        end
      end

      response "422", "already open or invalid transition" do
        let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "403", "forbidden for participants" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:Authorization) { "Bearer #{participant_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Raffle not found")
        end
      end
    end
  end

  path "/api/v1/raffles/{id}/close" do
    parameter name: :id, in: :path, type: :integer

    post "Close a raffle (open → closed)" do
      tags "Raffles"
      produces "application/json"
      security [ { bearerAuth: [] } ]

      response "200", "raffle closed" do
        let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["raffle"]["status"]).to eq("closed")
        end
      end

      response "422", "not open, cannot close" do
        let(:raffle) { create(:raffle, :draft, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "403", "forbidden for participants" do
        let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery) }
        let(:id)     { raffle.id }
        let(:Authorization) { "Bearer #{participant_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Forbidden")
        end
      end

      response "404", "not found" do
        let(:id) { 0 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Raffle not found")
        end
      end
    end
  end
end
