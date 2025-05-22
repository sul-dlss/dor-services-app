# frozen_string_literal: true

# Generates a report of SDR objects ids and their total size in bytes
#
# bin/rails r -e production "FileSizes.report"
#
# Or if you want to limit the results (e.g. top 100)
#
# bin/rails r -e production "FileSizes.report(100)"
#
class FileSizes
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier, SUM(files.size) AS size_bytes
    FROM dros,
      LATERAL (
        SELECT JSONB_ARRAY_ELEMENTS(
          JSONB_PATH_QUERY_ARRAY(
            structural,
            '$.contains[*].structural.contains[*].size'
          )
        )::NUMERIC AS size
        FROM dros dros2
        WHERE dros2.external_identifier = dros.external_identifier
      ) AS files
    GROUP BY dros.external_identifier
    ORDER BY size_bytes DESC
  SQL

  def self.report(limit = 'ALL')
    sql = "#{SQL} LIMIT #{limit}"
    puts 'druid,size_bytes'
    ActiveRecord::Base.connection.execute(sql).each do |row|
      puts [row['external_identifier'], row['size_bytes'].to_i].to_csv
    end
  end
end
