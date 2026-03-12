require "rails_helper"

RSpec.describe Raffles::CreateRaffleService do
  let(:organization) { create(:organization) }
  let(:lottery)      { create(:lottery) }
  let(:valid_params) do
    {
      title:        "My Raffle",
      description:  "Test raffle",
      ticket_price: "25.00",
      draw_mode:    "centena",
      draw_date:    (Date.current + 30.days).to_s,
      lottery_id:   lottery.id
    }
  end

  subject(:service) { described_class.new(params, organization) }

  describe "#call" do
    context "with valid params" do
      let(:params) { valid_params }

      it "returns success: true" do
        expect(service.call[:success]).to be true
      end

      it "creates the raffle" do
        expect { service.call }.to change(Raffle, :count).by(1)
      end

      it "assigns the raffle to the organization" do
        result = service.call
        expect(result[:raffle].organization).to eq(organization)
      end

      it "sets status to draft by default" do
        result = service.call
        expect(result[:raffle]).to be_draft
      end
    end

    context "with prizes" do
      let(:params) do
        valid_params.merge(
          raffle_prizes_attributes: [
            { position: 1, description: "Notebook", lottery_prize_position: 1 },
            { position: 2, description: "R$ 500", lottery_prize_position: 2 }
          ]
        )
      end

      it "creates the raffle with prizes" do
        result = service.call
        expect(result[:success]).to be true
        expect(result[:raffle].raffle_prizes.count).to eq(2)
      end
    end

    context "with invalid params" do
      let(:params) { valid_params.merge(title: "") }

      it "returns success: false" do
        expect(service.call[:success]).to be false
      end

      it "returns errors" do
        expect(service.call[:errors]).to be_present
      end

      it "does not create a raffle" do
        expect { service.call }.not_to change(Raffle, :count)
      end
    end

    context "with draw_date in the past" do
      let(:params) { valid_params.merge(draw_date: Date.current - 1) }

      it "returns success: false" do
        expect(service.call[:success]).to be false
      end

      it "includes draw_date error" do
        errors = service.call[:errors]
        expect(errors.join).to match(/draw date/i)
      end
    end

    context "with negative ticket price" do
      let(:params) { valid_params.merge(ticket_price: -5) }

      it "returns success: false" do
        expect(service.call[:success]).to be false
      end
    end
  end
end
