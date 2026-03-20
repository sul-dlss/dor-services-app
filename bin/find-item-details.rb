#!/usr/bin/env ruby
# frozen_string_literal: true

# Given a list of druids, export their item details.

require_relative '../config/environment'
require 'csv'
require 'optparse'
require 'tty-progressbar'

BATCH_SIZE = 1000

def druids(batch)
  batch.map(&:first)
end

def sql_for_batch(batch)
  druid_clause = druids(batch).map { |d| "'#{d}'" }.join(', ')
  <<~SQL.squish
    SELECT ro.external_identifier as druid,
    jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
    jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo,
    jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
    jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
    jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
    ro.object_type as object_type
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.external_identifier in (#{druid_clause})
  SQL
end

def result(batch)
  ActiveRecord::Base.connection.execute(sql_for_batch(batch))
end

def create_report(csv)
  puts %w[druid title second_column collection_druid collection_title apo apo_name project_tag HRID
          object_type].join(',')
  csv.each_slice(BATCH_SIZE) do |batch|
    second_column = batch.to_h
    result(batch).each do |row|
      druid = row['druid']
      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
      apo_druid = row['apo']
      apo_name = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version&.label
      project_tags = AdministrativeTag.where(druid:).map { |at| at.tag_label.tag }.join(',')

      puts [
        druid,
        (row['structured_title'] || row['title'])&.delete("\n"),
        second_column[druid],
        collection_druid,
        collection_name,
        apo_druid,
        apo_name,
        project_tags,
        row['hrid'],
        row['object_type']
      ].to_csv
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: find-item-details.rb -f FILE'

  opts.on('-f', '--file FILE', 'CSV file with identifiers in the first column') do |f|
    options[:file] = f
  end

  opts.on('--headers', 'Skip the first row of the CSV file (treat as header row)') do
    options[:headers] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!

abort('Error: a CSV file must be provided via -f or --file') unless options[:file]
abort("Error: file '#{options[:file]}' not found") unless File.exist?(options[:file])

CSV.open(options[:file]) do |csv|
  csv.shift if options[:headers]
  create_report(csv)
end
