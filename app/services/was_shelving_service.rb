# frozen_string_literal: true

# Copy shelvable web archives files into web archiving stacks
class WasShelvingService
  class WasShelvingError < StandardError; end

  def self.shelve(cocina_object)
    new(cocina_object).shelve
  end

  def initialize(cocina_object)
    @cocina_object = cocina_object
    @druid = cocina_object.externalIdentifier
  end

  attr_reader :cocina_object, :druid

  def shelve
    # get the list of shelvable files from cocina and shelve those that are available in the workspace
    filenames.each do |file|
      workspace_pathname = workspace_content_dir.join(file)
      was_stacks_pathname = was_stacks_dir.join(file)
      copy_file(workspace_pathname, was_stacks_pathname) if File.exist?(workspace_pathname)
    end
  end

  def was_stacks_dir
    # determine destination web archiving stacks directory
    @was_stacks_dir ||= begin
      stacks_druid = DruidTools::StacksDruid.new(druid, was_stacks_location)
      Pathname(stacks_druid.path)
    end
  end

  def was_stacks_location
    collection_druid = cocina_object.structural&.isMemberOf&.first

    raise WasShelvingService::WasShelvingError, 'Web archive object missing collection' unless collection_druid

    "#{Settings.stacks.web_archiving_stacks}/#{collection_druid.delete_prefix('druid:')}"
  end

  def workspace_content_dir
    # determine current workspace location of object's content file
    @workspace_content_dir ||= begin
      workspace_druid = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
      Pathname(workspace_druid.content_dir(true))
    end
  end

  def filenames
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
  end
end
