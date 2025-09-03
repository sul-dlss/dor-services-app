# frozen_string_literal: true

# Generates a report of repository objects with fileset externalIdentifiers
# that don't look like URIs.

# bin/rails r -e production "ExternalIdentifierUris.report"
#
class ExternalIdentifierUris
  SQL = <<~SQL.squish.freeze
    SELECT druid, created_at, updated_at, external_id
    FROM (
      SELECT
        ro.external_identifier AS druid,
        ro.created_at,
        ro.updated_at,
        rov.structural -> 'contains' -> 0 ->> 'externalIdentifier' AS external_id
      FROM repository_objects AS ro, repository_object_versions AS rov
      WHERE ro.head_version_id = rov.id
        AND ro.object_type = 'dro'
    ) Q1
    WHERE
      external_id IS NOT NULL
      AND (
        external_id NOT LIKE 'http%' 
        OR external_id LIKE 'http%http%'
      );
  SQL

  def self.report
    puts 'druid,created_at,updated_at,external_id'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      puts [row['druid'], row['created_at'], row['updated_at'], row['external_id']].to_csv
    end
  end
end
