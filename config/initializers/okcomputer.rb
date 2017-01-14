require 'okcomputer'

# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true
OkComputer::Registry.deregister "database" # no database in this app

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

class SymphonyCheck < OkComputer::HttpCheck
  def perform_request
    Timeout.timeout(request_timeout) do
      SymphonyReader.client.get(url.to_s)
    end
  end
end

OkComputer::Registry.register 'version', CustomAppVersionCheck.new
OkComputer::Registry.register 'external-symphony', SymphonyCheck.new(Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: 12345 })

OkComputer.make_optional %w(external-symphony)
