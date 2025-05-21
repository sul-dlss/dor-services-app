# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerialsOpen.report(filename: '/opt/app/deploy/dor-services-app/druid_list.txt')"
class DigitalSerialsOpen
  # Report on head_version open status for a provided set of druids.
  # filename should be the full path.  There won't be shell expansion, so e.g. "~" for home dir won't work.
  def self.report(...)
    new(...).report
  end

  def initialize(filename:)
    @filename = filename
  end

  attr_reader :filename

  def report
    raise "Input file missing: #{filename}" unless File.exist?(filename)

    puts 'druid,status'
    File.foreach(filename, chomp: true) do |druid|
      object = RepositoryObject.find_by(external_identifier: druid)
      status = object.open? ? 'OPEN' : 'CLOSED'

      line = [
        druid,
        status
      ].join(',')

      puts "#{line}\n"
    rescue StandardError => e
      logger.error("Unexpected error for druid: #{e}")
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log', "#{self.class.name}.log"))
  end
end
