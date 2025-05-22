# frozen_string_literal: true

# Generates a report of SDR objects, their types and the number of files they
# contain.
#
# bin/rails r -e production "FileCounts.report"
#
# Or if you want to limit the results (e.g. top 100)
#
# bin/rails r -e production "FileCounts.report(100)"
#
class FileCounts
  SQL = <<~SQL.squish.freeze
    SELECT DISTINCT(ro.external_identifier),
      rov.content_type,
      JSONB_ARRAY_LENGTH(
        JSONB_PATH_QUERY_ARRAY(
          rov.structural,
          '$.contains[*].structural.contains[*].filename'
        )
      ) AS count
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE ro.object_type = 'dro' AND rov.id = ro.head_version_id
    ORDER BY count DESC
  SQL

  def self.report(limit = 'ALL')
    sql = "#{SQL} LIMIT #{limit}"
    puts 'druid,content_type,file_count'
    ActiveRecord::Base.connection.execute(sql).each do |row|
      puts [row['external_identifier'], row['content_type'], row['count']].to_csv
    end
  end
end
