#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fedora_cache'
require 'fedora_loader'

MODS_NS = Cocina::Models::Mapping::FromMods::Description::DESC_METADATA_NS

# Report generator using Fedora objects stored in cache.
class Report
  class CacheFailure < RuntimeError; end

  Result = Struct.new(:druid, :apo, :catkey, :result)

  def initialize(name:, dsids:, yield_cocina: false, nil_cache_failure: false)
    @name = name
    @dsids = dsids
    @options = build_options
    @yield_cocina = yield_cocina
    @nil_cache_failure = nil_cache_failure
  end

  def run
    results = Parallel.map(druids, progress: "Running #{name} report") do |druid|
      report_result =
        begin
          yield(*datastreams(druid))
        rescue CacheFailure
          next
        end

      next unless report_result

      if options[:fast]
        Result.new(druid, nil, nil, report_result)
      else
        begin
          fedora_obj = loader.load(druid)
          Result.new(druid, fedora_obj.admin_policy_object_id, fedora_obj.catkey, report_result)
        rescue FedoraLoader::Unmapped
          Result.new(druid, nil, nil, report_result)
        end
      end
    end

    write_report(results)
  end

  private

  attr_reader :name, :options, :dsids, :yield_cocina, :nil_cache_failure

  def datastreams(druid)
    dsids.map do |dsid|
      if yield_cocina && dsid == 'descMetadata'
        cache_result = cache.label_and_desc_metadata(druid)
        if cache_result.failure?
          next nil if nil_cache_failure

          raise CacheFailure
        end

        label, descriptive_xml = cache_result.value!

        props = Cocina::Models::Mapping::FromMods::Description.props(
          mods: Nokogiri::XML(descriptive_xml),
          druid: druid,
          label: label
        )
        Cocina::Models::Description.new(props)
      else
        cache_result = cache.datastream(druid, dsid)
        if cache_result.failure?
          next nil if nil_cache_failure

          raise CacheFailure
        end

        Nokogiri::XML(cache_result.value!)
      end
    end
  end

  def write_report(results)
    CSV.open("#{name}.csv", 'w') do |writer|
      writer << %w[druid apo catkey message]
      results.compact.each do |result|
        writer << [result.druid,
                   result.apo,
                   result.catkey,
                   result.result.is_a?(String) ? result.result : nil]
      end
    end
  end

  def build_options
    options = { fast: false, input: 'druids.txt' }
    parser = OptionParser.new do |option_parser|
      option_parser.banner = "Usage: bin/reports/report-#{name} [options]"
      option_parser.on('-sSAMPLE', '--sample SAMPLE', Integer, 'Sample size, otherwise all druids in druids.txt.')
      option_parser.on('-f', '--fast', 'Do not retrieve additional object metadata (APO druid, catkey) for report.')
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

  def loader
    @loader ||= FedoraLoader.new(cache: cache)
  end

  def druids
    @druids ||= begin
      druids = File.read(options[:input]).split
      druids = druids.take(options[:sample]) if options[:sample]
      druids
    end
  end
end
