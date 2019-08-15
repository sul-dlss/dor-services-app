# frozen_string_literal: true

# Creates and removes the druid path from the filesystem
class DruidPath
  class SameContentExistsError < RuntimeError; end
  class DifferentContentExistsError < RuntimeError; end

  # @param [DruidTools::Druid] druid
  def initialize(druid:)
    @druid = druid
  end

  def mkdir(extra = nil)
    new_path = druid.path(extra)
    raise DifferentContentExistsError, "Unable to create directory, link already exists: #{new_path}" if File.symlink? new_path
    raise SameContentExistsError, "The directory already exists: #{new_path}" if File.directory? new_path

    FileUtils.mkdir_p(new_path)
  end

  def mkdir_with_final_link(source, extra = nil)
    new_path = druid.path(extra)
    raise DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}" if File.directory?(new_path) && !File.symlink?(new_path)

    real_path = File.expand_path('..', new_path)
    FileUtils.mkdir_p(real_path)
    FileUtils.ln_s(source, new_path, force: true)
  end

  def rmdir(extra = nil)
    parts = druid.tree
    parts << extra unless extra.nil?
    until parts.empty?
      dir = File.join(druid.base, *parts)
      begin
        FileUtils.rm(File.join(dir, '.DS_Store'), force: true)
        FileUtils.rmdir(dir)
      rescue Errno::ENOTEMPTY
        break
      end
      parts.pop
    end
  end

  private

  attr_reader :druid
end
