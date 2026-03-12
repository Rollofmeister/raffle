require "rails_helper"

RSpec.describe Raffles::TransitionRaffleService do
  let(:organization) { create(:organization) }
  let(:lottery)      { create(:lottery) }

  def service(raffle, target)
    described_class.new(raffle, target)
  end

  describe "#call" do
    context "allowed transitions" do
      it "draft → open: succeeds" do
        raffle = create(:raffle, :draft, organization: organization, lottery: lottery)
        result = service(raffle, :open).call
        expect(result[:success]).to be true
        expect(raffle.reload).to be_open
      end

      it "draft → cancelled: succeeds" do
        raffle = create(:raffle, :draft, organization: organization, lottery: lottery)
        result = service(raffle, :cancelled).call
        expect(result[:success]).to be true
        expect(raffle.reload).to be_cancelled
      end

      it "open → closed: succeeds" do
        raffle = create(:raffle, :open, organization: organization, lottery: lottery)
        result = service(raffle, :closed).call
        expect(result[:success]).to be true
        expect(raffle.reload).to be_closed
      end

      it "open → cancelled: succeeds" do
        raffle = create(:raffle, :open, organization: organization, lottery: lottery)
        result = service(raffle, :cancelled).call
        expect(result[:success]).to be true
      end

      it "closed → drawn: succeeds" do
        raffle = create(:raffle, :closed, organization: organization, lottery: lottery)
        result = service(raffle, :drawn).call
        expect(result[:success]).to be true
        expect(raffle.reload).to be_drawn
      end

      it "closed → cancelled: succeeds" do
        raffle = create(:raffle, :closed, organization: organization, lottery: lottery)
        result = service(raffle, :cancelled).call
        expect(result[:success]).to be true
      end
    end

    context "disallowed transitions" do
      it "draft → closed: fails" do
        raffle = create(:raffle, :draft, organization: organization, lottery: lottery)
        result = service(raffle, :closed).call
        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end

      it "draft → drawn: fails" do
        raffle = create(:raffle, :draft, organization: organization, lottery: lottery)
        result = service(raffle, :drawn).call
        expect(result[:success]).to be false
      end

      it "open → drawn: fails" do
        raffle = create(:raffle, :open, organization: organization, lottery: lottery)
        result = service(raffle, :drawn).call
        expect(result[:success]).to be false
      end

      it "open → draft: fails" do
        raffle = create(:raffle, :open, organization: organization, lottery: lottery)
        result = service(raffle, :draft).call
        expect(result[:success]).to be false
      end

      it "drawn → any: fails" do
        raffle = create(:raffle, :drawn, organization: organization, lottery: lottery)
        expect(service(raffle, :cancelled).call[:success]).to be false
        expect(service(raffle, :open).call[:success]).to be false
      end

      it "cancelled → any: fails" do
        raffle = create(:raffle, :cancelled, organization: organization, lottery: lottery)
        expect(service(raffle, :open).call[:success]).to be false
        expect(service(raffle, :draft).call[:success]).to be false
      end
    end

    context "error message" do
      it "includes the invalid transition in the error" do
        raffle = create(:raffle, :draft, organization: organization, lottery: lottery)
        result = service(raffle, :closed).call
        expect(result[:errors].join).to match(/draft.*closed/i)
      end
    end
  end
end
