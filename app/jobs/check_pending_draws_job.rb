class CheckPendingDrawsJob < ApplicationJob
  queue_as :default

  def perform
    Lottery.active.find_each do |lottery|
      lottery.lottery_schedules.active.each do |schedule|
        next unless schedule.draw_time_passed_today?
        next if schedule.today_draw.present?

        FetchDrawsJob.perform_later(
          lottery_id: lottery.id,
          date: Date.today.to_s
        )
      end
    end
  end
end
