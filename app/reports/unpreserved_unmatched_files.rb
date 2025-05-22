# frozen_string_literal: true

# Generates a report of unpreserved files that are not matched with preserved files.
# That is, files where "shelve = yes" and "preserve = no" that are contained in
# filesets that do not contain any files that have "preserve = yes"

# bin/rails r -e production "UnpreservedUnmatchedFiles.report"
#
class UnpreservedUnmatchedFiles
  SQL = <<~SQL.squish.freeze
    SELECT external_identifier,#{' '}
      jsonb_path_query_array(filesets, '$[*].structural.contains[*].filename') AS filenames
      FROM (
        SELECT external_identifier, jsonb_path_query_array(structural, '$.contains[*] ? (exists (@.structural.contains[*] ? (@.administrative.sdrPreserve == false && @.administrative.shelve == true) ) && !exists (@.structural.contains[*] ? (@.administrative.sdrPreserve == true) ))') AS filesets FROM dros
      ) AS fs
    WHERE jsonb_array_length(filesets) > 0;#{'  '}
  SQL

  def self.report
    puts 'druid,files'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      puts [row['external_identifier'], row['filenames']].to_csv
    end
  end
end
