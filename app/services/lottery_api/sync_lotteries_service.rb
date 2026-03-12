module LotteryApi
  class SyncLotteriesService
    def initialize(client: LotteryApi::Client.new)
      @client = client
    end

    def call
      lotteries_data = @client.lotteries
      schedules_data = @client.lottery_schedules

      lottery_counts = sync_lotteries(lotteries_data)
      schedule_counts = sync_schedules(schedules_data)

      { lotteries: lottery_counts, schedules: schedule_counts }
    end

    private

    def sync_lotteries(data)
      created = 0
      updated = 0

      Array(data).each do |item|
        lottery = Lottery.find_or_initialize_by(external_id: item["loteria_id"])
        new_record = lottery.new_record?

        lottery.assign_attributes(
          name: item["nome"],
          abbreviation: item["abreviacao"]
        )

        lottery.save!
        new_record ? created += 1 : updated += 1
      end

      { created: created, updated: updated }
    end

    def sync_schedules(data)
      created = 0
      updated = 0

      Array(data).each do |item|
        lottery = Lottery.find_by(external_id: item["loteria_id"])
        next unless lottery

        schedule = LotterySchedule.find_or_initialize_by(
          lottery: lottery,
          draw_time: item["sorteio"]
        )
        new_record = schedule.new_record?

        schedule.save!
        new_record ? created += 1 : updated += 1
      end

      { created: created, updated: updated }
    end
  end
end
