# frozen_string_literal: true

# Ensures that shelve-able files are in the staging area.  If they are not found
# in the staging area, it attempts to get it from preservation if the file hasn't
# been changed. Othewise it raises an error.
class ShelvableFilesStager
  class FileNotFound < RuntimeError; end

  def self.stage(...)
    new(...).stage
  end

  # @param filepaths [Array<String>] the list of filepaths to stage
  # @param workspace_content_pathname [Pathname] the workspace directory of the object
  # @param cocina_object [Cocina::Models::DRO] the cocina object
  # @raise [FileNotFound] if a file is not found in the content directory or preservation
  # @raise [Preservation::Client::Error] other preservation client errors
  def initialize(filepaths:, cocina_object:, workspace_content_pathname:)
    @filepaths = filepaths
    @cocina_object = cocina_object
    @workspace_content_pathname = workspace_content_pathname
  end

  # Ensure all the files are found in the object's content files in the workspace area
  def stage
    filepaths.each do |filepath|
      file_pathname = workspace_content_pathname.join(filepath)
      next if file_pathname.exist?

      copy_file_from_preservation(file_pathname:, filepath:)
    end
  end

  private

  attr_reader :filepaths, :workspace_content_pathname, :cocina_object

  # Try to copy from preservation into the workspace
  def copy_file_from_preservation(file_pathname:, filepath:)
    Rails.logger.info("Copying #{filepath} from preservation to #{file_pathname} for #{druid}")
    FileUtils.mkdir_p(file_pathname.dirname)
    received_bytes = 0
    File.open(file_pathname, 'wb') do |streamed|
      writer = proc do |chunk, overall_received_bytes|
        streamed.write chunk
        received_bytes = overall_received_bytes
      end
      Preservation::Client.objects.content(druid:, filepath:, version: version - 1, on_data: writer)
      check_filesize(file_pathname:, filepath:, received: received_bytes)
    end
  rescue Preservation::Client::NotFoundError, Faraday::ResourceNotFound
    file_pathname.delete if file_pathname.exist? # 404 body is written to file
    raise FileNotFound, "Unable to find #{filepath} in the content directory"
  end

  def check_filesize(file_pathname:, filepath:, received:)
    expected = cocina_filesize_for(filepath)
    return if expected.nil? || expected == received

    file_pathname.delete if file_pathname.exist?
    raise "File copied from preservation was not the expected size. Expected #{expected} bytes for #{filepath}; received #{received} bytes."
  end

  def cocina_filesize_for(filename)
    cocina_object.structural.contains.each do |file_set|
      file_set.structural.contains.each do |file|
        return file.size if file.filename == filename
      end
    end
    nil
  end

  def druid
    cocina_object.externalIdentifier
  end

  def version
    cocina_object.version
  end
end
