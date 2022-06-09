# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "BadW3cdtfDates.report"
class BadW3cdtfDates
  def self.report
    puts "item_druid,collection_druid,catkey,invalid_values\n" # rubocop:disable Rails/Output

    Dro.where("jsonb_path_exists(description, '$.**.date.encoding.code ? (@ ==  \"w3cdtf\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    bad_values = path.on(dro.description.to_json).uniq.filter_map do |date_value|
      Time.w3cdtf(date_value)
      nil
    rescue ArgumentError
      # NOTE: the upstream W3CDTF implementation in the `rss` gem does not
      #       allow two patterns that should be valid per the specification:
      #
      # * YYYY
      # * YYYY-MM
      #
      # So we catch the false positives from the upstream gem and allow
      # these two patterns to validate
      /\A\d{4}(-0[1-9]|1[0-2])?\Z/.match?(date_value) ? nil : date_value
    end

    return if bad_values.empty?

    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{bad_values.join(';')}\n" # rubocop:disable Rails/Output
  end

  private

  attr_reader :dro

  def path
    @path ||= JsonPath.new('$..date..[?(@.encoding.code == "w3cdtf")]..value')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
