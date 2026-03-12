class FetchDrawsJob < ApplicationJob
  queue_as :default

  def perform(lottery_id:, date:)
    lottery = Lottery.find(lottery_id)
    LotteryApi::FetchDrawsService.new(lottery: lottery, date: date).call
  end
end
