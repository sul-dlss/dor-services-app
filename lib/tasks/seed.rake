# frozen_string_literal: true

SEEDS_DIR = 'seeds'

namespace :seed do # rubocop:disable Metrics/BlockLength
  desc 'Stash an APO, Collection, or Agreement seed'
  task :stash, [:druid] => :environment do |_task, args|
    FileUtils.mkdir_p(SEEDS_DIR)

    bare_druid = args[:druid].delete_prefix('druid:')

    cocina_object = Cocina::Models.without_metadata(CocinaObjectStore.find("druid:#{bare_druid}"))

    filepath = "#{SEEDS_DIR}/#{bare_druid}.json"
    File.write(filepath, JSON.pretty_generate(cocina_object.to_h))

    puts "Wrote seed to #{filepath}"
  end

  desc 'Creates an APO, Collection, or Agreement seed'
  task :create, [:druid] => :environment do |_task, args|
    Settings.enabled_features.create_ur_admin_policy = false

    file = File.read("#{SEEDS_DIR}/#{args[:druid].delete_prefix('druid:')}.json")
    cocina_params = JSON.parse(file)

    cocina_params['version'] = 1
    druid = cocina_params.delete('externalIdentifier')
    cocina_params['description'].delete('purl')
    # An agreement might have files, but do not need for seeding.
    cocina_params['structural']['contains'] = [] if cocina_params.key?('structural')

    cocina_request_object = Cocina::Models.build_request(cocina_params)

    raise 'Only Collections and APOs are supported' if cocina_request_object.dro? && cocina_request_object.type != Cocina::Models::ObjectType.agreement

    CreateObjectService.create(cocina_request_object, id_minter: -> { druid })

    client = WorkflowClientFactory.build
    client.create_workflow_by_name(druid, 'registrationWF', version: 1)
    client.create_workflow_by_name(druid, 'accessionWF', version: 1)

    puts "Seeded #{druid}"
  end
end
