# frozen_string_literal: true

# Ensures that shelve-able files are in the staging area.  If they are not found
# in the staging area, it attempts to get it from preservation if the file hasn't
# been changed. Othewise it raises an error.
class LegacyShelvableFilesStager
  class FileNotFound < RuntimeError; end

  def self.stage(identifier, preserve_diff, shelve_diff, content_dir)
    new(identifier, preserve_diff, shelve_diff, content_dir).stage
  end

  def initialize(identifier, preserve_diff, shelve_diff, content_dir)
    @identifier = identifier
    @preserve_diff = preserve_diff
    @shelve_diff = shelve_diff
    @content_dir = content_dir
  end

  # Ensure all the files are found in the object's content files in the workspace area
  def stage
    return true if filelist.empty?

    filelist.each do |file|
      next if file_in_staging?(file)

      # If they preserved the file in a previous version, but didn't shelve it, we can copy it to staging.
      # We infer that the file is unchanged if was not also added to preservation in this version.
      next if file_deltas[:added].include?(file) && file_previously_in_preservation?(file) && copy_file_from_preservation(file)

      raise FileNotFound, "Unable to find #{file} in the content directory"
    end

    true
  end

  private

  attr_reader :identifier, :preserve_diff, :shelve_diff, :content_dir, :content_metadata

  delegate :file_deltas, to: :shelve_diff

  def filelist
    @filelist ||= file_deltas[:modified] + file_deltas[:added] + file_deltas[:copyadded].collect { |_old, new| new }
  end

  def file_in_staging?(file)
    filepath(file).exist?
  end

  def filepath(file)
    content_dir.join(file)
  end

  def file_previously_in_preservation?(file)
    preserve_diff.file_deltas[:added].exclude?(file)
  end

  # Copy from preservation into the workspace
  def copy_file_from_preservation(file)
    FileUtils.mkdir_p(filepath(file).dirname)
    File.open(filepath(file), 'wb') do |streamed|
      writer = proc do |chunk, _overall_received_bytes|
        streamed.write chunk
      end
      Preservation::Client.objects.content(druid: identifier, filepath: file, on_data: writer)
    end
  end
end
