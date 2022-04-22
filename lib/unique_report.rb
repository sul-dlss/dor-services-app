#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fedora_cache'

MODS_NS = Cocina::Models::Mapping::FromMods::Description::DESC_METADATA_NS

# Report generator that returns a list of unique values using Fedora objects stored in cache.
class UniqueReport
  class CacheFailure < RuntimeError; end

  def initialize(name:, dsids:)
    @name = name
    @dsids = dsids
    @options = build_options
  end

  def run
    results = Parallel.map(druids, progress: "Running #{name} report") do |druid|
      yield(*datastream_xmls(druid))
    rescue CacheFailure
      next
    end

    write_report(results)
  end

  private

  attr_reader :name, :options, :dsids

  def datastream_xmls(druid)
    dsids.map do |dsid|
      cache_result = cache.datastream(druid, dsid)
      raise CacheFailure if cache_result.failure?

      Nokogiri::XML(cache_result.value!)
    end
  end

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
      option_parser.on('-iFILENAME', '--input FILENAME', String, 'File containing list of druids (instead of druids.txt).')
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
