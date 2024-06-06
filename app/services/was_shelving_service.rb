# frozen_string_literal: true

# Copy shelve-able web archives files into web archiving stacks
class WasShelvingService
  class ConfigurationError < RuntimeError; end
  class WasShelvingError < StandardError; end

  def self.shelve(cocina_object)
    new(cocina_object).shelve
  end

  def initialize(cocina_object)
    raise ConfigurationError, 'Missing configuration Settings.stacks.local_workspace_root' if Settings.stacks.local_workspace_root.nil?
    raise WasShelvingService::WasShelvingError, 'Missing structural' if cocina_object.structural.nil?

    @cocina_object = cocina_object
    @druid = cocina_object.externalIdentifier
  end

  attr_reader :cocina_object, :druid

  def shelve
    # determine destination web archiving stacks location
    stacks_druid = DruidTools::StacksDruid.new(druid, was_stacks_location)
    stacks_object_pathname = Pathname(stacks_druid.path)

    # determine current workspace location of object's content file
    workspace_druid = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
    workspace_content_pathname = Pathname(workspace_druid.content_dir(true))

    # get the list of shelvable files from cocina and shelve those that are available in the workspace
    files_for(cocina_object).each do |file|
      workspace_pathname = workspace_content_pathname.join(file)
      stacks_pathname = stacks_object_pathname.join(file)
      copy_file(workspace_pathname, stacks_pathname) if File.exist?(workspace_pathname)
    end
  end

  def was_stacks_location
    collection_druid = cocina_object.structural&.isMemberOf&.first

    raise WasShelvingService::WasShelvingError, 'Web archive object missing collection' unless collection_druid

    "/web-archiving-stacks/data/collections/#{collection_druid.delete_prefix('druid:')}"
  end

  def files_for(cocina_object)
    [].tap do |files_list|
      cocina_object.structural.contains.each do |file_set|
        file_set.structural.contains.each do |file|
          files_list << file.filename if file.administrative.shelve
        end
      end
    end
  end

  def copy_file(workspace_pathname, stacks_pathname)
    stacks_pathname.parent.mkpath unless stacks_pathname.parent.exist?

    Rails.logger.debug("[Was Shelve] Copying #{workspace_pathname} to #{stacks_pathname}")
    FileUtils.cp workspace_pathname.to_s, stacks_pathname.to_s
    # Change permissions
    FileUtils.chmod 'u=rw,go=r', stacks_pathname.to_s
  end
end
