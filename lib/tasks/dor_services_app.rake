# frozen_string_literal: true

namespace :dsa do
  desc 'Embargo release'
  task embargo_release: :environment do
    EmbargoReleaseService.release_all
  end

  desc 'Open a new version from an existing version'
  task :open_version, %i[druid description from_version] => :environment do |_task, args|
    repository_object = RepositoryObject.find_by!(external_identifier: args[:druid])
    VersionService.open(cocina_object: repository_object.to_cocina, description: args[:description],
                        assume_accessioned: false, from_version:  args[:from_version].to_i)
  end

  desc 'Move a user version'
  task :move_user_version, %i[druid user_version to_version] => :environment do |_task, args|
    UserVersionService.move(druid: args[:druid], version: args[:to_version].to_i, user_version: args[:user_version].to_i)
  end

  desc 'Closes a repository object without changing a user version'
  task :close_version, %i[druid] => :environment do |_task, args|
    repository_object = RepositoryObject.find_by!(external_identifier: args[:druid])
    VersionService.close(druid: args[:druid], version: repository_object.head_version.version, user_version_mode: :none)
  end
end
