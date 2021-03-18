#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fedora_cache'
require 'fedora_loader'

MODS_NS = Cocina::FromFedora::Descriptive::DESC_METADATA_NS

# Report generator using Fedora objects stored in cache.
class Report
  Result = Struct.new(:druid, :apo, :catkey, :result)

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

      report_result = report_func.call(ng_xml)
      if !report_result
        nil
      elsif options[:fast]
        Result.new(druid, nil, nil, report_result)
      else
        begin
          fedora_obj = loader.load(druid)
          Result.new(druid, fedora_obj.admin_policy_object_id, fedora_obj.catkey, report_result)
        rescue FedoraLoader::Unmapped
          Result.new(druid, nil, nil, report_result)
        end
      end
    end.compact
  end

  def write_report(results)
    CSV.open("#{name}.csv", 'w') do |writer|
      writer << %w[druid apo catkey message]
      results.each do |result|
        writer << [result.druid,
                   result.apo,
                   result.catkey,
                   result.result.is_a?(String) ? result.result : nil]
      end
    end
  end

  def build_options
    options = { fast: false }
    parser = OptionParser.new do |option_parser|
      option_parser.banner = "Usage: bin/reports/report-#{name} [options]"
      option_parser.on('-sSAMPLE', '--sample SAMPLE', Integer, 'Sample size, otherwise all druids in druids.txt.')
      option_parser.on('-f', '--fast', 'Do not retrieve additional object metadata for report.')
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

  def loader
    @loader ||= FedoraLoader.new(cache: cache)
  end

  def druids
    @druids ||= begin
      druids = File.read('druids.txt').split
      druids = druids.take(options[:sample]) if options[:sample]
      druids
    end
  end
end
