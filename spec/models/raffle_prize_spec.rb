require "rails_helper"

RSpec.describe RafflePrize, type: :model do
  subject(:prize) { build(:raffle_prize) }

  describe "associations" do
    it { is_expected.to belong_to(:raffle) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_presence_of(:lottery_prize_position) }

    it "validates position is between 1 and 5" do
      expect(build(:raffle_prize, position: 0)).not_to be_valid
      expect(build(:raffle_prize, position: 6)).not_to be_valid
      expect(build(:raffle_prize, position: 1)).to be_valid
      expect(build(:raffle_prize, position: 5)).to be_valid
    end

    it "validates lottery_prize_position is between 1 and 5" do
      expect(build(:raffle_prize, lottery_prize_position: 0)).not_to be_valid
      expect(build(:raffle_prize, lottery_prize_position: 6)).not_to be_valid
      expect(build(:raffle_prize, lottery_prize_position: 1)).to be_valid
      expect(build(:raffle_prize, lottery_prize_position: 5)).to be_valid
    end

    context "uniqueness of position scoped to raffle" do
      let(:raffle) { create(:raffle) }

      it "disallows duplicate position within the same raffle" do
        create(:raffle_prize, raffle: raffle, position: 1)
        duplicate = build(:raffle_prize, raffle: raffle, position: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:position]).to be_present
      end

      it "allows same position in different raffles" do
        other_raffle = create(:raffle)
        create(:raffle_prize, raffle: raffle, position: 1)
        prize = build(:raffle_prize, raffle: other_raffle, position: 1)
        expect(prize).to be_valid
      end
    end

    context "DB unique constraint on (raffle_id, position)" do
      it "raises on direct DB insert with duplicate" do
        raffle = create(:raffle)
        create(:raffle_prize, raffle: raffle, position: 1)

        expect do
          RafflePrize.insert!({ raffle_id: raffle.id, position: 1, description: "X",
                                lottery_prize_position: 1, created_at: Time.current, updated_at: Time.current })
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
