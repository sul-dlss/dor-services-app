# frozen_string_literal: true

# Generates a report of files in the SDR which lack media types.
#
# bin/rails r -e production "EmptyMediatypes.report"
#
class EmptyMediatypes
  SQL = <<~SQL.squish.freeze
    SELECT
      external_identifier,
      file ->> 'filename'
    FROM dros
    CROSS JOIN JSONB_PATH_QUERY(
      structural,
      '$.contains[*].structural.contains[*]'
    ) AS file
    WHERE file ->> 'hasMimeType' IS NULL
  SQL

  def self.report
    CSV do |csv|
      csv << %w[druid filename]
      ActiveRecord::Base.connection.execute(SQL).each do |row|
        csv << row.values
      end
    end
  end
end
