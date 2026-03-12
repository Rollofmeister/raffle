require "rails_helper"

RSpec.describe LotterySchedule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:lottery) }
    it { is_expected.to have_many(:draws).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:lottery_schedule) }

    it { is_expected.to validate_presence_of(:draw_time) }
    it "validates uniqueness of draw_time scoped to lottery_id" do
      create(:lottery_schedule, draw_time: "14:20")
      duplicate = build(:lottery_schedule, lottery: LotterySchedule.last.lottery, draw_time: "14:20")
      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:active_schedule)   { create(:lottery_schedule, active: true) }
    let!(:inactive_schedule) { create(:lottery_schedule, :inactive) }

    describe ".active" do
      it "returns only active schedules" do
        expect(LotterySchedule.active).to include(active_schedule)
        expect(LotterySchedule.active).not_to include(inactive_schedule)
      end
    end
  end

  describe "#today_draw" do
    let(:schedule) { create(:lottery_schedule) }

    context "when a draw exists for today" do
      let!(:draw) { create(:draw, lottery_schedule: schedule, draw_date: Date.today) }

      it "returns the draw" do
        expect(schedule.today_draw).to eq(draw)
      end
    end

    context "when no draw exists for today" do
      it "returns nil" do
        expect(schedule.today_draw).to be_nil
      end
    end
  end

  describe "#draw_time_passed_today?" do
    let(:schedule) { build(:lottery_schedule, draw_time: draw_time, active: active) }

    context "when schedule is inactive" do
      let(:active) { false }
      let(:draw_time) { "00:01" }

      it "returns false" do
        expect(schedule.draw_time_passed_today?).to be false
      end
    end

    context "when schedule is active and time has passed" do
      let(:active) { true }
      let(:draw_time) { "00:01" }

      it "returns true" do
        expect(schedule.draw_time_passed_today?).to be true
      end
    end

    context "when schedule is active and time has not passed" do
      let(:active) { true }
      let(:draw_time) { "23:59" }

      it "returns false" do
        expect(schedule.draw_time_passed_today?).to be false
      end
    end
  end
end
