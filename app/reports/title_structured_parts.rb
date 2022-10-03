# frozen_string_literal: true

# Report dro objects with a title containing a structuredValue with a part name or part number type
#   for those dros with a ckey
#
# Invoke via:
# bin/rails r -e production "TitleStructuredParts.report"
#
class TitleStructuredParts
  PROPERTY = 'title.**.structuredValue'
  TYPE_REGEX = '(part name)|(part number)'
  FORM_VALUE = '^map$'
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  STRUCTURED_VALUE_JSON_PATH = "strict $.#{PROPERTY}[*] ? (@.type like_regex \"#{TYPE_REGEX}\")".freeze
  FORM_JSON_PATH = "$.form.value ? (@ like_regex \"#{FORM_VALUE}\")".freeze

  CKEY_JSON_PATH = '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId'
  SQL_QUERY = <<~SQL.squish.freeze
    SELECT
      external_identifier as item_druid,
      jsonb_path_query(identification, '#{CKEY_JSON_PATH}') ->> 0 as catkey,
      jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_druid,
      title_parts,
      form
    FROM "dros",
      jsonb_path_query(dros.description, '#{STRUCTURED_VALUE_JSON_PATH}') title_parts,
      jsonb_path_query(dros.description, '#{FORM_JSON_PATH}') form
    WHERE
      jsonb_path_exists(dros.description, '#{STRUCTURED_VALUE_JSON_PATH}') AND
      jsonb_path_exists(dros.description, '#{FORM_JSON_PATH}')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name,title parts\n"
    rows(SQL_QUERY).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a
    grouped_rows = sql_result_rows.group_by { |row| row['item_druid'] }
    item_druids = grouped_rows.keys
    item_druids.map do |item_druid|
      item_rows = grouped_rows[item_druid]
      # each item_row is a hash with keys:   item_druid, catkey, collection_id, title_parts
      catkey = item_rows.first['catkey']
      collection_druid = item_rows.first['collection_druid']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label if collection_druid

      [
        item_druid,
        catkey,
        collection_druid,
        "\"#{collection_name}\"",
        title_parts(item_rows).join(';')
      ].join(',')
    end
  end

  # each row is a hash with keys: item_druid, catkey, collection_id, title_parts
  #   where title_parts is a structuredValue
  # find structuredValue type part number or part name, and return  array of strings, like
  #   ['part number: 5', 'part name: a mighty wind']
  def self.title_parts(rows)
    results = []
    rows.each do |row|
      structured_value = JSON.parse(row['title_parts']).compact
      title_part_type = structured_value['type']
      results << "#{title_part_type}:#{structured_value['value']}" if ['part name', 'part number'].include?(title_part_type) # rubocop:disable Performance/CollectionLiteralInLoop:
    end
    results.uniq
  end
end
