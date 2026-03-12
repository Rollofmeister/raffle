require "rails_helper"

RSpec.describe Draw, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:lottery_schedule) }
  end

  describe "validations" do
    subject { build(:draw) }

    it { is_expected.to validate_presence_of(:draw_date) }
    it { is_expected.to validate_uniqueness_of(:draw_date).scoped_to(:lottery_schedule_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processed: 1, failed: 2) }
  end

  describe "scopes" do
    let!(:pending_draw)   { create(:draw, :pending) }
    let!(:processed_draw) { create(:draw, :pending, draw_date: 1.day.from_now) }
    let!(:failed_draw)    { create(:draw, :failed, draw_date: 2.days.from_now) }

    before { processed_draw.update!(status: :processed) }

    describe ".pending" do
      it "returns only pending draws" do
        expect(Draw.pending).to include(pending_draw)
        expect(Draw.pending).not_to include(processed_draw, failed_draw)
      end
    end

    describe ".processed" do
      it "returns only processed draws" do
        expect(Draw.processed).to include(processed_draw)
        expect(Draw.processed).not_to include(pending_draw, failed_draw)
      end
    end
  end

  describe "#prize_for" do
    let(:draw) do
      build(:draw, prizes: [
        { "position" => 1, "value" => "1234", "group_value" => "12", "group_name" => "Elefante" },
        { "position" => 2, "value" => "5678", "group_value" => "56", "group_name" => "Galo" }
      ])
    end

    it "returns the value for the given position" do
      expect(draw.prize_for(1)).to eq("1234")
      expect(draw.prize_for(2)).to eq("5678")
    end

    it "returns nil for a position that does not exist" do
      expect(draw.prize_for(99)).to be_nil
    end
  end
end
