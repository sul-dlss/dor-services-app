# frozen_string_literal: true

require 'json'

# Generates a report of repository objects with files that are
# shelved but not published

# bin/rails r -e production "ShelvedNotPublished.report"
#
class ShelvedNotPublished
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier,
      jsonb_path_query(rov.administrative, '$.hasAdminPolicy') AS admin_policy,
      rov.content_type,
      jsonb_path_query_array(rov.structural, '$.contains[*].structural.contains[*].administrative[*].shelve') AS shelve,
      jsonb_path_query_array(rov.structural, '$.contains[*].structural.contains[*].administrative[*].publish') AS publish
      FROM repository_objects AS ro, repository_object_versions AS rov
      WHERE ro.head_version_id = rov.id
      AND ro.object_type = 'dro'
  SQL

  def self.report
    puts 'druid,admin_policy,type'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      next unless row['shelve'].include?('true') && row['publish'].include?('false')

      JSON.parse(row['shelve']).each_with_index do |val, key|
        next unless val == true
        next unless JSON.parse(row['publish'])[key] == false

        puts [row['external_identifier'], row['admin_policy'], row['content_type']].to_csv
      end
    end
  end
end
