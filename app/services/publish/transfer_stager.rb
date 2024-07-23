# frozen_string_literal: true

module Publish
  # Encapsulates logic for transferring files to the transfer staging area.
  class TransferStager
    def self.copy(...)
      new(...).copy
    end

    # @param [String] druid for the object to be published
    # @param [Hash] filepath_map map of filenames to transfer filenames (UUIDs)
    # @param [Pathname] workspace_content_pathname path to the workspace content directory
    def initialize(druid:, filepath_map:, workspace_content_pathname:)
      @druid = druid
      @filepath_map = filepath_map
      @workspace_content_pathname = workspace_content_pathname
    end

    def copy
      filepath_map.each do |filename, stage_filename|
        copy_file(workspace_content_pathname.join(filename), transfer_stage_pathname.join(stage_filename))
      end
    end

    private

    attr_reader :druid, :filepath_map, :workspace_content_pathname

    def copy_file(src_pathname, dest_pathname)
      return if dest_pathname.exist?

      Rails.logger.info("Copying #{src_pathname} (#{src_pathname.size} bytes) to #{dest_pathname} for #{druid}")
      FileUtils.copy(src_pathname, dest_pathname)

      raise "Copy #{src_pathname} to #{dest_pathname} failed" unless dest_pathname.exist? && dest_pathname.size == src_pathname.size
    end

    def transfer_stage_pathname
      @transfer_stage_pathname ||= Pathname(Settings.stacks.transfer_stage_root)
    end
  end
end
