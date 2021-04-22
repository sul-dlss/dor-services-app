#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fedora_cache'

MODS_NS = Cocina::FromFedora::Descriptive::DESC_METADATA_NS

# Report generator that returns a list of unique values using Fedora objects stored in cache.
class UniqueReport
  def initialize(name:, dsid:, report_func:)
    @name = name
    @dsid = dsid
    @options = build_options
    @report_func = report_func
  end

  def run
    results = run_report
    write_report(results)
  end

  private

  attr_reader :name, :options, :dsid, :report_func

  def run_report
    Parallel.map(druids, progress: 'Testing') do |druid|
      cache_result = cache.datastream(druid, dsid)
      next if cache_result.failure?

      ng_xml = Nokogiri::XML(cache_result.value!)

      report_func.call(ng_xml)
    end.compact.flatten.uniq
  end

  def write_report(results)
    CSV.open("#{name}.csv", 'w') do |writer|
      results.each do |result|
        writer << [result]
      end
    end
  end

  def build_options
    options = {}
    parser = OptionParser.new do |option_parser|
      option_parser.banner = "Usage: bin/reports/report-#{name} [options]"
      option_parser.on('-sSAMPLE', '--sample SAMPLE', Integer, 'Sample size, otherwise all druids in druids.txt.')
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
      druids = File.read('druids.txt').split
      druids = druids.take(options[:sample]) if options[:sample]
      druids
    end
  end
end
