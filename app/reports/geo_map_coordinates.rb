# frozen_string_literal: true

# see https://github.com/sul-dlss/dor-services-app/issues/4702

# Invoke via:
# bin/rails r -e production "GeoMapCoordinates.report"
class GeoMapCoordinates
  JSON_PATH_TYPE = 'strict $.**.subject.**.type'
  JSON_PATH_VALUE = 'strict $.**.subject.**.value'

  # Finds an object like this: https://argo.stanford.edu/view/druid:bb051ch9980
  # "description": {
  #   "subject": [
  #      {
  #           "value": "E 13°59'00\"--E 34°28'00\"/S 22°07'00\"--S 35°39'00\"",
  #           "type": "map coordinates"
  #       }
  #   ],

  SQL = <<~SQL.squish.freeze
    SELECT external_identifier,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           (jsonb_path_exists(description, '#{JSON_PATH_TYPE} ? (@ like_regex "(map coordinates)")') AND
           jsonb_path_exists(description, '#{JSON_PATH_VALUE} ? (@ like_regex "^.+")'))
  SQL

  def self.report
    puts "item_druid,collection_druid\n"

    ActiveRecord::Base.connection.execute(SQL).each do |row|
      puts [row['external_identifier'], row['collection_id']].to_csv
    end
  end
end
