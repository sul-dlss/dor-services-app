# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "BadEdtfDates.report"
class BadEdtfDates
  def self.report
    puts "item_druid,collection_druid,catkey,invalid_values\n" # rubocop:disable Rails/Output

    Dro.where("jsonb_path_exists(description, '$.**.date.encoding.code ? (@ ==  \"edtf\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    bad_values = path.on(dro.description.to_json).uniq.filter_map do |date_value|
      Date.edtf!(date_value)
      nil
    rescue ArgumentError
      # NOTE: the upstream EDTF implementation in the `edtf` gem does not
      #       allow a valid pattern that we use (possibly because only level
      #       0 of the spec was implemented?):
      #
      # * Y-20555
      #
      # So we catch the false positives from the upstream gem and allow
      # this pattern to validate
      /\AY-?\d{5,}\Z/.match?(date_value) ? nil : date_value
    end

    return if bad_values.empty?

    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{bad_values.join(';')}\n" # rubocop:disable Rails/Output
  end

  private

  attr_reader :dro

  def path
    @path ||= JsonPath.new('$..date..[?(@.encoding.code == "edtf")]..value')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
