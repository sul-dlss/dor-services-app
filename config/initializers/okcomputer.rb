require 'okcomputer'

# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

class CustomAppVersionCheck < OkComputer::AppVersionCheck
  def version
    version_from_version_file || super
  end

  private

  def version_from_version_file
    if File.exist?(Rails.root.join("VERSION"))
      File.read(Rails.root.join("VERSION")).chomp
    end
  end
end

OkComputer::Registry.register 'version', CustomAppVersionCheck.new
