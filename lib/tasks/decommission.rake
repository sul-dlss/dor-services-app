# frozen_string_literal: true

namespace :decommission do
  desc 'Decommission items by druid'
  task :item, %i[druid sunetid description] => :environment do |_t, args|
    if args[:druid].nil? || args[:sunetid].nil? || args[:description].nil?
      raise '*** druid, sunetid, and description are required arguments'
    end

    druid = args[:druid]
    sunetid = args[:sunetid]
    description = args[:description]

    DecommissionService.new(druid:, description:, sunetid:).decommission
  rescue Error => e
    puts "Failed to decommission #{args[:druid]}: #{e.message}"
  end

  # Reads a CSV file with columns: druid,sunetid,description
  # If sunetid and description are not provided in a row, uses the
  # provided arguments as defaults.
  # Logs results to a timestamped CSV in log
  task :items, %i[file sunetid description] => :environment do |_t, args|
    raise '*** file is a required argument' if args[:file].nil?

    file = args[:file]
    CSV.open("log/decommission_items_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv",
             'w',
             write_headers: true,
             headers: %w[druid status message]) do |log|
      CSV.read(file, headers: true).each do |row|
        druid = row['druid']
        sunetid = row['sunetid'] || args[:sunetid]
        description = row['description'] || args[:description]

        DecommissionService.new(druid:, description:, sunetid:).decommission
        log << [druid, 'SUCCESS', 'Decommissioned successfully']
      rescue Error => e
        log << [druid, 'FAILURE', e.message]
      end
    end
  end
end
