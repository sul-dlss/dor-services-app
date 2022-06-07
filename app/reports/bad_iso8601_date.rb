# frozen_string_literal: true

# Invoke via:
# bin/rails runner "BadIso8601Date.report"
class BadIso8601Date
  def self.report
    path = JsonPath.new('$..date[*][?(@.encoding.code == "iso8601")].value')
    Dro.where("jsonb_path_exists(description, '$.**.date.encoding.code ? (@ ==  \"iso8601\")')").find_each do |dro|
      json = dro.description.to_json
      date_values = path.on(json)
      date_values.each do |value|
        DateTime.iso8601(value)
      rescue Date::Error
        catkey = dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
        puts "#{dro.external_identifier},#{catkey},#{value}\n" # rubocop:disable Rails/Output
      end
    end
  end
end
