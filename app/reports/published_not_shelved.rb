# frozen_string_literal: true

require 'json'

# Generates a report of repository objects with files that are
# published but not shelved

# bin/rails r -e production "PublishedNotShelved.report"
#
class PublishedNotShelved
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier,
      jsonb_path_query(rov.administrative, '$.hasAdminPolicy') AS admin_policy,
      rov.content_type,
      jsonb_path_query_array(rov.structural, '$.contains[*].structural.contains[*].administrative[*].shelve') AS shelve,
      jsonb_path_query_array(rov.structural, '$.contains[*].structural.contains[*].administrative[*].publish') AS publish
      FROM repository_objects AS ro, repository_object_versions AS rov
      WHERE ro.head_version_id = rov.id
      AND ro.object_type = 'dro'
      AND rov.content_type != '#{Cocina::Models::ObjectType.webarchive_binary}'
  SQL

  def self.report
    puts 'druid,admin_policy,type'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      next unless row['publish'].include?('true') && row['shelve'].include?('false')

      JSON.parse(row['publish']).each_with_index do |val, key|
        next unless val == true
        next unless JSON.parse(row['shelve'])[key] == false

        puts [row['external_identifier'], row['admin_policy'], row['content_type']].to_csv
      end
    end
  end
end
