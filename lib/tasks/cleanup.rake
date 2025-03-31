# frozen_string_literal: true

namespace :cleanup do
  # Stop accessioning in progress for the supplied druid (if possible).
  # bundle exec rake cleanup:stop_accessioning['druid:ab123bc4567']
  # bundle exec rake cleanup:stop_accessioning['druid:ab123bc4567',:dryrun] # shows output but does not actually delete
  desc 'Stop Accessioning for single druid'
  task :stop_accessioning, %i[druid dryrun] => :environment do |_task, args|
    dryrun = args[:dryrun] || false
    druid = args[:druid]

    $stdout.puts "This will completely stop accessioning for #{druid}. Are you sure? [y/n]:"
    raise 'Aborting' unless $stdin.gets.chomp == 'y'

    CleanupService.stop_accessioning(druid, dryrun:)
  end

  # Stop accessioning in progress for multiple druids supplied in a CSV (one per line, no header)
  # bundle exec rake cleanup:bulk_stop_accessioning['tmp/druids.csv']
  # bundle exec rake cleanup:bulk_stop_accessioning['tmp/druids.csv',:dryrun] # shows output but does not actually
  #   delete
  desc 'Stop Accessioning for multiple druids provided in a CSV'
  task :bulk_stop_accessioning, %i[input_file dryrun] => :environment do |_task, args|
    input_file = args[:input_file]
    raise 'CSV file not found' unless File.exist? input_file

    dryrun = args[:dryrun] || false
    $stdout.puts '*** DRY RUN - NO ACTIONS WILL BE PERFORMED' if dryrun

    rows = CSV.read(input_file)
    $stdout.puts "This will completely stop accessioning for #{rows.size} objects. Are you sure? [y/n]:"
    raise 'Aborting' unless $stdin.gets.chomp == 'y'

    rows.each do |row|
      druid = row.first
      $stdout.puts '====='
      $stdout.puts druid

      begin
        CleanupService.stop_accessioning(druid, dryrun:)
      rescue StandardError => e
        $stdout.puts "Error stopping accessioning for #{druid}: #{e.message} #{e.backtrace.join("\n")}"
      end
    end
  end
end
