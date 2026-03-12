require "rails_helper"

RSpec.describe CheckPendingDrawsJob, type: :job do
  describe "#perform" do
    let!(:active_lottery) { create(:lottery, active: true) }
    let!(:inactive_lottery) { create(:lottery, :inactive) }

    context "when a schedule has passed today without a draw" do
      let!(:schedule) do
        create(:lottery_schedule, lottery: active_lottery, draw_time: "00:01", active: true)
      end

      it "enqueues FetchDrawsJob for the schedule" do
        expect {
          described_class.perform_now
        }.to have_enqueued_job(FetchDrawsJob).with(
          lottery_id: active_lottery.id,
          date: Date.today.to_s
        )
      end
    end

    context "when a schedule has a draw for today" do
      let!(:schedule) do
        create(:lottery_schedule, lottery: active_lottery, draw_time: "00:01", active: true)
      end
      let!(:existing_draw) { create(:draw, lottery_schedule: schedule, draw_date: Date.today) }

      it "does not enqueue FetchDrawsJob" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(FetchDrawsJob)
      end
    end

    context "when a schedule has not yet passed today" do
      let!(:schedule) do
        create(:lottery_schedule, lottery: active_lottery, draw_time: "23:59", active: true)
      end

      it "does not enqueue FetchDrawsJob" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(FetchDrawsJob)
      end
    end

    context "when the lottery is inactive" do
      let!(:schedule) do
        create(:lottery_schedule, lottery: inactive_lottery, draw_time: "00:01", active: true)
      end

      it "does not enqueue FetchDrawsJob" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(FetchDrawsJob)
      end
    end

    context "when the schedule is inactive" do
      let!(:schedule) do
        create(:lottery_schedule, lottery: active_lottery, draw_time: "00:01", active: false)
      end

      it "does not enqueue FetchDrawsJob" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_job(FetchDrawsJob)
      end
    end
  end
end
