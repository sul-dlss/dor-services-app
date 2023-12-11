# frozen_string_literal: true

# Report dro objects that meet requirements for schema.org video markup

# Invoke via:
# bin/rails r -e production "VideoDateTypes.report"
class VideoDateTypes
  FILE_SET_TYPE = 'https://cocina.sul.stanford.edu/models/resources/video'

  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as item_druid,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(structural, '$.contains[*] ? (@.type == "#{FILE_SET_TYPE}")')
           AND jsonb_path_exists(description, '$.event.date[*] ? (@.type == "publication")')
           AND jsonb_path_exists(access, '$.download ? (@ == "world")')
           AND jsonb_path_exists(structural, '$.contains[*].structural.contains[*] ? (@.hasMimeType like_regex "^video") .access.download ? (@ == "world")')
  SQL

  def self.report
    puts "item_druid,collection_druid,collection_name,dros with fileset type of #{FILE_SET_TYPE} and date type publication \n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [row['item_druid'], collection_druid, "\"#{collection_name}\""].join(',')
    end
  end
end
