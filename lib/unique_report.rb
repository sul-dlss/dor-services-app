#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fedora_cache'

MODS_NS = Cocina::FromFedora::Descriptive::DESC_METADATA_NS

# Report generator that returns a list of unique values using Fedora objects stored in cache.
class UniqueReport
  def initialize(name:, dsid:)
    @name = name
    @dsid = dsid
    @options = build_options
  end

  def run
    results = Parallel.map(druids, progress: 'Testing') do |druid|
      cache_result = cache.datastream(druid, dsid)
      next if cache_result.failure?

      ng_xml = Nokogiri::XML(cache_result.value!)

      yield ng_xml
    end

    write_report(results)
  end

  private

  attr_reader :name, :options, :dsid

  def write_report(results)
    CSV.open("#{name}.csv", 'w') do |writer|
      results.compact.flatten.uniq.sort.each do |result|
        writer << [result]
      end
    end
  end

  def build_options
    options = { input: 'druids.txt' }
    parser = OptionParser.new do |option_parser|
      option_parser.banner = "Usage: bin/reports/report-#{name} [options]"
      option_parser.on('-sSAMPLE', '--sample SAMPLE', Integer, 'Sample size, otherwise all druids in druids.txt.')
      option_parser.on('-iFILENAME', '--input FILENAME', String,
                       'File containing list of druids (instead of druids.txt).')
      option_parser.on('-h', '--help', 'Displays help.') do
        puts option_parser
        exit
      end
    end
    parser.parse!(into: options)
    options
  end

  def cache
    @cache ||= FedoraCache.new
  end

  def druids
    @druids ||= begin
      druids = File.read(options[:input]).split
      druids = druids.take(options[:sample]) if options[:sample]
      druids
    end
  end
end
