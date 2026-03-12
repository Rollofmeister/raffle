require "rails_helper"

RSpec.describe Raffles::UpdateRaffleService do
  let(:organization) { create(:organization) }
  let(:lottery)      { create(:lottery) }
  let(:raffle)       { create(:raffle, :draft, organization: organization, lottery: lottery) }

  subject(:service) { described_class.new(raffle, params) }

  describe "#call" do
    context "updating a draft raffle" do
      let(:params) { { title: "New Title", draw_mode: "milhar" } }

      it "returns success: true" do
        expect(service.call[:success]).to be true
      end

      it "updates the title" do
        service.call
        expect(raffle.reload.title).to eq("New Title")
      end

      it "allows updating draw_mode in draft" do
        service.call
        expect(raffle.reload).to be_milhar
      end
    end

    context "updating an open raffle" do
      let(:raffle) { create(:raffle, :open, organization: organization, lottery: lottery) }
      let(:params) { { title: "Updated Title", ticket_price: "30.00" } }

      it "returns success: true" do
        expect(service.call[:success]).to be true
      end

      it "updates allowed fields" do
        service.call
        expect(raffle.reload.title).to eq("Updated Title")
      end

      it "ignores draw_mode changes when open" do
        params_with_mode = { title: "Test", draw_mode: "milhar" }
        service = described_class.new(raffle, params_with_mode)
        # Service filters out draw_mode, model also validates
        result = service.call
        expect(raffle.reload).to be_centena
        # It may still succeed because draw_mode is filtered by service
        expect(result[:success]).to be true
      end
    end

    context "updating a closed raffle" do
      let(:raffle) { create(:raffle, :closed, organization: organization, lottery: lottery) }
      let(:params) { { title: "New Title" } }

      it "returns success: false" do
        expect(service.call[:success]).to be false
      end

      it "returns an error about status" do
        errors = service.call[:errors]
        expect(errors.join).to match(/closed/i)
      end
    end

    context "adding prizes via nested attributes" do
      let(:params) do
        {
          raffle_prizes_attributes: [
            { position: 1, description: "Notebook", lottery_prize_position: 1 }
          ]
        }
      end

      it "creates the prize" do
        expect { service.call }.to change(RafflePrize, :count).by(1)
      end
    end

    context "removing a prize with _destroy" do
      let!(:prize) { create(:raffle_prize, raffle: raffle, position: 1) }
      let(:params) do
        { raffle_prizes_attributes: [ { id: prize.id, _destroy: "1" } ] }
      end

      it "destroys the prize" do
        # Reload to clear stale association cache (prize was created after raffle validation cached the empty scope)
        expect { described_class.new(raffle.reload, params).call }.to change(RafflePrize, :count).by(-1)
      end
    end

    context "with invalid params" do
      let(:params) { { title: "" } }

      it "returns success: false" do
        expect(service.call[:success]).to be false
      end

      it "returns errors" do
        expect(service.call[:errors]).to be_present
      end
    end
  end
end
