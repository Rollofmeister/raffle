require "rails_helper"

RSpec.describe LotteryApi::SyncLotteriesService do
  let(:client) { instance_double(LotteryApi::Client) }
  let(:service) { described_class.new(client: client) }

  let(:lotteries_data) do
    [
      { "loteria_id" => 1, "nome" => "Loteria Federal", "abreviacao" => "LF" },
      { "loteria_id" => 3, "nome" => "PT-RIO", "abreviacao" => "PTR" }
    ]
  end

  let(:schedules_data) do
    [
      { "loteria_id" => 3, "nome" => "PT-RIO", "sorteio" => "14:20" },
      { "loteria_id" => 3, "nome" => "PT-RIO", "sorteio" => "16:20" },
      { "loteria_id" => 3, "nome" => "PT-RIO", "sorteio" => "18:20" }
    ]
  end

  before do
    allow(client).to receive(:lotteries).and_return(lotteries_data)
    allow(client).to receive(:lottery_schedules).and_return(schedules_data)
  end

  describe "#call" do
    context "when there are no existing records" do
      it "creates lotteries" do
        expect { service.call }.to change(Lottery, :count).by(2)
      end

      it "creates lottery schedules" do
        expect { service.call }.to change(LotterySchedule, :count).by(3)
      end

      it "returns the correct counts" do
        result = service.call
        expect(result[:lotteries]).to eq(created: 2, updated: 0)
        expect(result[:schedules]).to eq(created: 3, updated: 0)
      end
    end

    context "when lotteries already exist" do
      before { create(:lottery, external_id: 1, name: "Old Name") }

      it "updates existing lotteries" do
        service.call
        expect(Lottery.find_by(external_id: 1).name).to eq("Loteria Federal")
      end

      it "returns the correct counts" do
        result = service.call
        expect(result[:lotteries]).to eq(created: 1, updated: 1)
      end

      it "does not create duplicate lotteries" do
        expect { service.call }.to change(Lottery, :count).by(1)
      end
    end

    context "when schedules already exist" do
      before do
        lottery = create(:lottery, external_id: 3)
        create(:lottery_schedule, lottery: lottery, draw_time: "14:20")
      end

      it "does not create duplicate schedules" do
        service.call
        lottery = Lottery.find_by(external_id: 3)
        expect(lottery.lottery_schedules.where(draw_time: "14:20").count).to eq(1)
      end

      it "returns the correct schedule counts" do
        result = service.call
        expect(result[:schedules][:updated]).to eq(1)
        expect(result[:schedules][:created]).to eq(2)
      end
    end

    context "when a schedule references a lottery not yet synced" do
      let(:schedules_data) do
        [ { "loteria_id" => 999, "nome" => "Unknown", "sorteio" => "10:00" } ]
      end

      it "skips the schedule without error" do
        expect { service.call }.not_to raise_error
        expect(LotterySchedule.count).to eq(0)
      end
    end
  end
end
