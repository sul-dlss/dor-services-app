# frozen_string_literal: true

# Report dro objects with file sets of a given type

# Invoke via:
# bin/rails r -e production "FileSetTypes.report"
class FileSetTypes
  # NOTE: JSON_PATH may need to be changed, in addition to PROPERTY

  FILE_SET_TYPE = 'https://cocina.sul.stanford.edu/models/resources/main-original'
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{FILE_SET_TYPE}".freeze # when property is array

  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as item_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(structural, '$.contains[*] ? (@.type == "#{FILE_SET_TYPE}")')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,dros with fileset type of #{FILE_SET_TYPE}\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        row['item_druid'],
        row['catalogRecordId'],
        collection_druid,
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
