# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "BadIso8601Dates.report"
class BadIso8601Dates
  def self.report
    puts "item_druid,collection_druid,catkey,invalid_values\n"

    Dro.where("jsonb_path_exists(description, '$.**.date.encoding.code ? (@ ==  \"iso8601\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    bad_values = path.on(dro.description.to_json).uniq.filter_map do |date_value|
      DateTime.iso8601(date_value)
      nil
    rescue Date::Error
      date_value
    end

    return if bad_values.empty?

    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{bad_values.join(';')}\n"
  end

  private

  attr_reader :dro

  def path
    @path ||= JsonPath.new('$..date..[?(@.encoding.code == "iso8601")]..value')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
