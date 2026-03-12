require "rails_helper"

RSpec.describe Lottery, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:lottery_schedules).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:lottery) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:external_id) }
  end

  describe "scopes" do
    let!(:active_lottery)   { create(:lottery, active: true) }
    let!(:inactive_lottery) { create(:lottery, :inactive) }

    describe ".active" do
      it "returns only active lotteries" do
        expect(Lottery.active).to include(active_lottery)
        expect(Lottery.active).not_to include(inactive_lottery)
      end
    end
  end
end
