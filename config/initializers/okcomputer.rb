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
    Rails.root.join('VERSION').read.chomp if Rails.root.join('VERSION').exist?
  end
end

class FolioCheck < OkComputer::Check
  def check
    Timeout.timeout(5) do
      Catalog::FolioReader.to_marc(barcode: '12345')
    end
  rescue StandardError => e
    mark_failure
    "#{e.class.name} received: #{e.message}."
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
OkComputer::Registry.register 'external-folio', FolioCheck.new
OkComputer::Registry.register 'background_jobs', OkComputer::SidekiqLatencyCheck.new('default', Settings.sidekiq.latency_threshold)
OkComputer::Registry.register 'feature-tables-have-data', TablesHaveDataCheck.new

class RabbitQueueExistsCheck < OkComputer::Check
  attr_reader :queue_names, :conn

  def initialize(queue_names)
    @queue_names = Array(queue_names)
    @conn = Bunny.new(hostname: Settings.rabbitmq.hostname,
                      vhost: Settings.rabbitmq.vhost,
                      username: Settings.rabbitmq.username,
                      password: Settings.rabbitmq.password)
    super()
  end

  def check
    conn.start
    status = conn.status
    missing_queue_names = queue_names.reject { |queue_name| conn.queue_exists?(queue_name) }
    if missing_queue_names.empty?
      mark_message "'#{queue_names.join(', ')}' exists, connection status: #{status}"
    else
      mark_message "'#{missing_queue_names.join(', ')}' does not exist"
      mark_failure
    end
    conn.close
  rescue StandardError => e
    mark_message "Error: '#{e}'"
    mark_failure
  end
end

OkComputer::Registry.register 'rabbit-queues', RabbitQueueExistsCheck.new(['dsa.create-event', 'dor.indexing-by-druid']) if Settings.rabbitmq.enabled

OkComputer.make_optional %w(external-folio)

OkComputer::Registry.register 'external-solr', OkComputer::HttpCheck.new("#{Settings.solr.url.gsub(%r{/$}, '')}/admin/ping")
