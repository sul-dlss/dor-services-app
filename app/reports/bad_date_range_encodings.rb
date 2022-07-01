# frozen_string_literal: true

# Written for https://github.com/sul-dlss/dor-services-app/issues/4130
# This is for finding a structured date ranges where the second point has no encoding
# Invoke via:
# bin/rails r -e production "BadDateRangeEncodings.report"
class BadDateRangeEncodings
  def self.report
    puts "item_druid,collection_druid,catkey,values\n" # rubocop:disable Rails/Output

    # find all objects that have an edtf date encoding in structuredValue
    Dro.where("jsonb_path_exists(description, '$.**.date.structuredValue.encoding.code ? (@ ==  \"edtf\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    # extract date values for which there is no encoding
    bad_values = path.on(dro.description.to_json).map do |date_nodes|
      date_nodes.filter_map { |date_node| date_node['value'] if date_node['encoding'].blank? }
    end.flatten

    return if bad_values.empty?

    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{bad_values.join(';')}\n" # rubocop:disable Rails/Output
  end

  private

  attr_reader :dro

  # locate the date nodes within the structuredValue
  def path
    @path ||= JsonPath.new('$..date..structuredValue')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
