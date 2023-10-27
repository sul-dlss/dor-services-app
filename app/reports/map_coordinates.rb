# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "MapCoordinates.report"
class MapCoordinates
  SQL = <<~SQL.squish.freeze
    SELECT external_identifier, jsonb_path_query_array(description, '$.subject[*] ? (@.type == "map coordinates").value') AS coordinates
      FROM dros
      where content_type = 'https://cocina.sul.stanford.edu/models/map';
  SQL

  def self.report
    puts "druid,coordinates\n"
    rows(SQL).each do |row|
      puts row
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    result.to_a.filter { |row| row['coordinates'] != '[]' }.map do |row|
      [row['external_identifier'], row['coordinates']].join(',')
    end
  end
end
