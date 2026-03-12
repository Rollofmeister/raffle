require "rails_helper"

RSpec.describe LotteryApi::FetchDrawsService do
  let(:client) { instance_double(LotteryApi::Client) }
  let(:lottery) { create(:lottery, external_id: 3) }
  let(:schedule_1420) { create(:lottery_schedule, lottery: lottery, draw_time: "14:20") }
  let(:schedule_1620) { create(:lottery_schedule, lottery: lottery, draw_time: "16:20") }
  let(:date) { Date.new(2026, 3, 12) }
  let(:service) { described_class.new(lottery: lottery, date: date, client: client) }

  let(:draws_data) do
    [
      {
        "horario" => "14:20",
        "posicoes" => [
          { "posicao" => 1, "valor" => "1234", "grupo_valor" => "12", "grupo_nome" => "Elefante" },
          { "posicao" => 2, "valor" => "5678", "grupo_valor" => "56", "grupo_nome" => "Galo" }
        ]
      },
      {
        "horario" => "16:20",
        "posicoes" => [
          { "posicao" => 1, "valor" => "4321", "grupo_valor" => "43", "grupo_nome" => "Burro" }
        ]
      }
    ]
  end

  before do
    allow(client).to receive(:draws).with(date: date, loteria_id: 3).and_return(draws_data)
    schedule_1420
    schedule_1620
  end

  describe "#call" do
    it "creates draws for each schedule" do
      expect { service.call }.to change(Draw, :count).by(2)
    end

    it "returns the created draws" do
      draws = service.call
      expect(draws.size).to eq(2)
      expect(draws).to all(be_a(Draw))
    end

    it "sets draw status to processed" do
      service.call
      expect(Draw.all).to all(be_processed)
    end

    it "stores prizes in the draw" do
      service.call
      draw = Draw.find_by(lottery_schedule: schedule_1420, draw_date: date)
      expect(draw.prizes.size).to eq(2)
      expect(draw.prize_for(1)).to eq("1234")
    end

    it "maps Portuguese keys to normalized format" do
      service.call
      draw = Draw.find_by(lottery_schedule: schedule_1420, draw_date: date)
      prize = draw.prizes.first
      expect(prize["position"]).to eq(1)
      expect(prize["value"]).to eq("1234")
      expect(prize["group_value"]).to eq("12")
      expect(prize["group_name"]).to eq("Elefante")
    end

    context "when a draw already exists for the date" do
      before do
        create(:draw, lottery_schedule: schedule_1420, draw_date: date, status: :pending)
      end

      it "does not create a duplicate draw" do
        expect { service.call }.to change(Draw, :count).by(1)
      end

      it "updates the existing draw" do
        service.call
        draw = Draw.find_by(lottery_schedule: schedule_1420, draw_date: date)
        expect(draw).to be_processed
        expect(draw.prizes).not_to be_empty
      end
    end

    context "when the API returns a result for an unknown schedule time" do
      let(:draws_data) do
        [ { "horario" => "99:99", "posicoes" => [] } ]
      end

      it "skips the result without error" do
        expect { service.call }.not_to raise_error
        expect(Draw.count).to eq(0)
      end
    end

    context "when accepting a string date" do
      let(:service) { described_class.new(lottery: lottery, date: "2026-03-12", client: client) }

      it "parses the date and works correctly" do
        expect { service.call }.to change(Draw, :count).by(2)
      end
    end
  end
end
