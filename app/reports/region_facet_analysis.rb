# frozen_string_literal: true

# Generate a report of DROs that have at leaste one event with a displayLabel
#
# bin/rails r -e production "RegionFacetAnalysis.report"
#
class RegionFacetAnalysis
  # JSONB_SUBJECT_TYPE_QUERY = "'$.subject[*] ? (@.type == \"place\")'"
  JSONB_SUBJECT_QUERY = 'strict $.subject'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
          jsonb_path_query(description, '$.subject[*] ? (@.type == "place")') as subject
          FROM "dros"
          WHERE
          jsonb_path_exists(description, '$.subject[*] ? (@.type == "place")')
          LIMIT 100
  SQL

  def self.report
    puts "druid,value,uri,source_uri,source_code\n"

    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      # collection_druid = row['collection_druid']
      # collection_name = Collection.find_by(external_identifier: collection_druid)&.label
      [
        row['item_druid'],
        row['subject']
        # row['subject']['source']&.fetch('uri'),
        # row['subject']['source']&.fetch('code')
      ].join(',')
    end
  end

end
