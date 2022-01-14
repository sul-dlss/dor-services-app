# frozen_string_literal: true

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
    File.read(Rails.root.join('VERSION')).chomp if File.exist?(Rails.root.join('VERSION'))
  end
end

class SymphonyCheck < OkComputer::HttpCheck
  def perform_request
    Timeout.timeout(request_timeout) do
      SymphonyReader.client.get(url.to_s)
    end
  end
end

# check models to see if at least they have some data
class TablesHaveDataCheck < OkComputer::Check
  def check
    msg = [
      BackgroundJobResult,
      TagLabel,
      Event,
      AdministrativeTag
    ].map { |klass| table_check(klass) }.join(' ')
    mark_message msg
  end

  private

  # @return [String] message
  def table_check(klass)
    # has at least 1 record
    return "#{klass.name} has data." if klass.any?

    mark_failure
    "#{klass.name} has no data."
  rescue => e # rubocop:disable Style/RescueStandardError
    mark_failure
    "#{e.class.name} received: #{e.message}."
  end
end

OkComputer::Registry.register 'version', CustomAppVersionCheck.new
OkComputer::Registry.register 'external-symphony', SymphonyCheck.new(format(Settings.catalog.symphony.base_url + Settings.catalog.symphony.marcxml_path, catkey: 12345))
OkComputer::Registry.register 'background_jobs', OkComputer::SidekiqLatencyCheck.new('default', 25)
OkComputer::Registry.register 'feature-tables-have-data', TablesHaveDataCheck.new

if Settings.rabbitmq.enabled
  OkComputer::Registry.register 'rabbit',
                                OkComputer::RabbitmqCheck.new(hostname: Settings.rabbitmq.hostname,
                                                              vhost: Settings.rabbitmq.vhost,
                                                              username: Settings.rabbitmq.username,
                                                              password: Settings.rabbitmq.password)
end

OkComputer.make_optional %w(external-symphony)
