require "rails_helper"

RSpec.describe Raffle, type: :model do
  subject(:raffle) { build(:raffle) }

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:lottery) }
    it { is_expected.to have_many(:raffle_prizes).dependent(:destroy) }
    it { is_expected.to have_many(:tickets).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:draw_mode).with_values(centena: 0, milhar: 1, dezena_de_milhar: 2) }
    it {
      is_expected.to define_enum_for(:status).with_values(draft: 0, open: 1, closed: 2, drawn: 3, cancelled: 4)
    }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_presence_of(:ticket_price) }
    it { is_expected.to validate_numericality_of(:ticket_price).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:draw_mode) }
    it { is_expected.to validate_presence_of(:draw_date) }

    context "draw_date future on create" do
      it "is invalid when draw_date is today" do
        raffle.draw_date = Date.current
        expect(raffle).not_to be_valid
        expect(raffle.errors[:draw_date]).to include("must be in the future")
      end

      it "is invalid when draw_date is in the past" do
        raffle.draw_date = Date.current - 1
        expect(raffle).not_to be_valid
      end

      it "is valid when draw_date is in the future" do
        raffle.draw_date = Date.current + 1
        expect(raffle).to be_valid
      end

      it "does not re-validate draw_date on update" do
        raffle = create(:raffle, draw_date: Date.current + 1)
        raffle.draw_date = Date.current - 1
        raffle.title = "Updated title"
        # draw_date past on update is allowed (no create validation)
        expect(raffle.errors[:draw_date]).to be_empty
      end
    end

    context "draw_mode immutability after draft" do
      it "allows draw_mode change in draft" do
        raffle = create(:raffle, :draft, draw_mode: :centena)
        raffle.draw_mode = :milhar
        expect(raffle).to be_valid
      end

      it "disallows draw_mode change when open" do
        raffle = create(:raffle, :open, draw_mode: :centena)
        raffle.draw_mode = :milhar
        expect(raffle).not_to be_valid
        expect(raffle.errors[:draw_mode]).to include("cannot be changed after leaving draft status")
      end

      it "disallows draw_mode change when closed" do
        raffle = create(:raffle, :closed, draw_mode: :centena)
        raffle.draw_mode = :milhar
        expect(raffle).not_to be_valid
      end
    end

    context "prizes count limit" do
      it "is invalid with more than 5 prizes" do
        raffle = build(:raffle)
        6.times { |i| raffle.raffle_prizes.build(position: i + 1, description: "Prize #{i}", lottery_prize_position: 1) }
        expect(raffle).not_to be_valid
        expect(raffle.errors[:raffle_prizes]).to include("cannot have more than 5 prizes")
      end

      it "is valid with exactly 5 prizes" do
        raffle = build(:raffle)
        5.times { |i| raffle.raffle_prizes.build(position: i + 1, description: "Prize #{i}", lottery_prize_position: 1) }
        expect(raffle).to be_valid
      end
    end
  end

  describe "#total_tickets" do
    it "returns 100 for centena" do
      expect(build(:raffle, draw_mode: :centena).total_tickets).to eq(100)
    end

    it "returns 1000 for milhar" do
      expect(build(:raffle, draw_mode: :milhar).total_tickets).to eq(1_000)
    end

    it "returns 10000 for dezena_de_milhar" do
      expect(build(:raffle, draw_mode: :dezena_de_milhar).total_tickets).to eq(10_000)
    end
  end

  describe "#may_transition_to?" do
    it "draft → open: allowed" do
      expect(build(:raffle, :draft).may_transition_to?("open")).to be true
    end

    it "draft → cancelled: allowed" do
      expect(build(:raffle, :draft).may_transition_to?("cancelled")).to be true
    end

    it "draft → closed: not allowed" do
      expect(build(:raffle, :draft).may_transition_to?("closed")).to be false
    end

    it "draft → drawn: not allowed" do
      expect(build(:raffle, :draft).may_transition_to?("drawn")).to be false
    end

    it "open → closed: allowed" do
      expect(build(:raffle, :open).may_transition_to?("closed")).to be true
    end

    it "open → cancelled: allowed" do
      expect(build(:raffle, :open).may_transition_to?("cancelled")).to be true
    end

    it "open → drawn: not allowed" do
      expect(build(:raffle, :open).may_transition_to?("drawn")).to be false
    end

    it "closed → drawn: allowed" do
      expect(build(:raffle, :closed).may_transition_to?("drawn")).to be true
    end

    it "closed → cancelled: allowed" do
      expect(build(:raffle, :closed).may_transition_to?("cancelled")).to be true
    end

    it "drawn → any: not allowed" do
      expect(build(:raffle, :drawn).may_transition_to?("cancelled")).to be false
      expect(build(:raffle, :drawn).may_transition_to?("open")).to be false
    end

    it "cancelled → any: not allowed" do
      expect(build(:raffle, :cancelled).may_transition_to?("open")).to be false
      expect(build(:raffle, :cancelled).may_transition_to?("draft")).to be false
    end
  end

  describe "soft delete" do
    it "discards the raffle without deleting" do
      raffle = create(:raffle)
      raffle.discard
      expect(Raffle.kept).not_to include(raffle)
      expect(Raffle.discarded).to include(raffle)
    end
  end

  describe "scopes" do
    let!(:draft_raffle)  { create(:raffle, :draft) }
    let!(:open_raffle)   { create(:raffle, :open) }
    let!(:closed_raffle) { create(:raffle, :closed) }

    it "for_participants returns only kept.open raffles" do
      expect(Raffle.for_participants).to include(open_raffle)
      expect(Raffle.for_participants).not_to include(draft_raffle, closed_raffle)
    end
  end
end
