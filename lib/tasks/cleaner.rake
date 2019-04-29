# frozen_string_literal: true

desc 'Delete all objects from the environment'
task delete_all_objects: :environment do
  puts 'Are you sure you want to destroy EVERYTHING? Type "DELETE" to confirm.'
  input = $stdin.gets.chomp
  exit if input != 'DELETE'

  total = ActiveFedora::Base.all.count
  progressbar = ProgressBar.create(title: 'Items to delete', total: total)
  ActiveFedora::Base.send(:connections).each do |conn|
    conn.search(nil) do |object|
      progressbar.increment
      next if object.pid.start_with?('fedora-system:')
      next unless DruidTools::Druid.valid?(object.pid)

      Dor::CleanupService.nuke!(object.pid)
    end
  end

  # Clear out anything else remaining in solr:
  conn = ActiveFedora::SolrService.instance.conn
  conn.delete_by_query('*:*')
  conn.commit

  Rake::Task['seeds'].invoke
end

desc 'Seed the repository with workflows and APOs'
task seed: :environment do
  druids = File.readlines(File.join(__dir__, 'seeds', 'druids'))
  druids.each do |line|
    druid, description = line.split(/\s/, 2)
    puts "Loading '#{description.chomp}'"
    file = File.join(__dir__, 'seeds', "#{druid}.xml")
    ActiveFedora::FixtureLoader.import_to_fedora(file, druid)
  end
end
