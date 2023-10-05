# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :cleanup do
  # Stop accessioning in progress for the supplied druid (if possible).
  # bundle exec rake cleanup:stop_accessioning['druid:ab123bc4567']
  # bundle exec rake cleanup:stop_accessioning['druid:ab123bc4567',:dryrun] # shows output but does not actually delete
  desc 'Stop Accessioning for single druid'
  task :stop_accessioning, [:druid, :dryrun] => :environment do |_task, args|
    dryrun = args[:dryrun] || false
    druid = args[:druid]

    $stdout.puts "This will completely stop accessioning for #{druid}. Are you sure? [y/n]:"
    raise 'Aborting' unless $stdin.gets.chomp == 'y'

    cleanup_druid(druid, dryrun:)
  end

  # Stop accessioning in progress for multiple druids supplied in a CSV (one per line, no header)
  # bundle exec rake cleanup:bulk_stop_accessioning['tmp/druids.csv']
  # bundle exec rake cleanup:bulk_stop_accessioning['tmp/druids.csv',:dryrun] # shows output but does not actually delete
  desc 'Stop Accessioning for multiple druids provided in a CSV'
  task :bulk_stop_accessioning, [:input_file, :dryrun] => :environment do |_task, args|
    input_file = args[:input_file]
    raise 'CSV file not found' unless File.exist? input_file

    dryrun = args[:dryrun] || false
    $stdout.puts '*** DRY RUN - NO ACTIONS WILL BE PERFORMED' if dryrun

    rows = CSV.read(input_file)
    num_druids = rows.size

    $stdout.puts "This will completely stop accessioning for #{num_druids} objects. Are you sure? [y/n]:"
    raise 'Aborting' unless $stdin.gets.chomp == 'y'

    rows.each do |row|
      druid = row.first
      $stdout.puts druid

      begin
        cleanup_druid(druid, dryrun:)
      rescue StandardError => e
        $stdout.puts "Error stopping accessioning for #{druid}: #{e.message} #{e.backtrace.join("\n")}"
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def cleanup_druid(druid, dryrun: false)
    backup_path = '/dor/staging/stopped' # path to move content before deleting from cleanup_paths
    cleanup_paths = [Settings.cleanup.local_workspace_root,
                     Settings.cleanup.local_assembly_root,
                     Settings.cleanup.local_export_home] # paths to backup and then delete
    workflows_to_delete = %w[accessionWF assemblyWF versioningWF] # workflows to delete

    # This will raise an exception if an invalid format (or no) druid is passed in
    druid_obj = DruidTools::Druid.new(druid)

    # Returns the druid with prefix even if not passed in with a prefix, e.g. druid:ab123bc4567
    druid = druid_obj.druid

    # Verify druid exists: this will raise an exception if the druid is not found
    object = CocinaObjectStore.find(druid)

    $stdout.puts '*** DRY RUN - NO ACTIONS WILL BE PERFORMED' if dryrun
    $stdout.puts "...object found is an item: version #{object.version}"

    # Verify the current version has not made it to preservation by checking if it is openable:
    # if it is, then it must have been sent to preservation and therefore we must stop.
    raise "v#{object.version} of the object has already been sent to preservation: cannot proceed" if VersionService.can_open?(druid:, version: object.version)

    # If `preservationIngestWF#complete-ingest` != completed, then a step in this workflow is likely in error (ie. preservation got part way and then failed)
    #  and we should stop, since extra remediation may be needed
    raise "v#{object.version} of the object has preservationIngestWF#complete-ingest not completed: cannot proceed" unless WorkflowClientFactory.build.workflow_status(druid:, workflow: 'preservationIngestWF', process: 'complete-ingest') == 'completed'

    $stdout.puts "...v#{object.version} of the object has not been sent to preservation"

    # Backup any content folders (e.g. in /dor/workspace, etc) if they exist and then delete original
    # Content is backed up to a base druid folder and then subfolders by workspace (allowing for multiple to exist)
    # e.g. /dor/workspace/ab/123/bc/4567/ab1234567 --> /dor/staging/stopped/ab123bc4567/workspace/content /metadata
    #      /dor/assembly/ab/123/bc/4567/ab1234567 ---> /dor/staging/stopped/ab123bc4567/assembly
    cleanup_paths.each do |path|
      content_path = DruidTools::Druid.new(druid, path) # e.g. /dor/workspace/ab/123/bc/4567/ab1234567

      $stdout.puts "...looking for #{content_path.path}"
      next unless File.directory?(content_path.path)

      base_backup_path = File.join(backup_path, druid_obj.id) # e.g. /dor/staging/stopped/ab123bc4567
      specific_backup_path = File.join(base_backup_path, File.basename(path)) # e.g. /dor/staging/stopped/ab123bc4567/workspace
      $stdout.puts "...found #{content_path.path}: copying to #{specific_backup_path} and then deleting"
      next if dryrun

      FileUtils.mkdir_p(base_backup_path)
      FileUtils.cp_r(content_path.path, specific_backup_path)
      PruneService.new(druid: content_path).prune!
    end

    # Delete workflows for the current object version
    workflows_to_delete.each do |workflow|
      $stdout.puts "..deleting workflow #{workflow}"
      WorkflowClientFactory.build.delete_workflow(druid:, workflow:, version: object.version) unless dryrun
    end

    # Let user know we are done
    $stdout.puts "...accessioning stopped complete for #{druid}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/BlockLength
