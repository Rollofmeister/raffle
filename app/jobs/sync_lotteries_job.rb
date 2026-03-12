class SyncLotteriesJob < ApplicationJob
  queue_as :default

  def perform
    LotteryApi::SyncLotteriesService.new.call
  end
end
