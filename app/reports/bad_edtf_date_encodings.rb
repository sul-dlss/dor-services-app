# frozen_string_literal: true

# Written for https://github.com/sul-dlss/dor-services-app/issues/4130
# Invoke via:
# bin/rails r -e production "BadEdtfDateEncodings.report"
class BadEdtfDateEncodings
  def self.report
    puts "item_druid,collection_druid,catkey,values\n" # rubocop:disable Rails/Output

    # find all objects that an edtf date encoding
    Dro.where("jsonb_path_exists(description, '$.**.date.encoding.code ? (@ ==  \"edtf\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    # extract date values for which there is no encoding
    bad_values = path.on(dro.description.to_json).filter_map { |date_node| date_node['value'] if date_node['encoding'].blank? }

    return if bad_values.empty?

    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{bad_values.join(';')}\n" # rubocop:disable Rails/Output
  end

  private

  attr_reader :dro

  # locate the nodes with the EDTF date encoding
  def path
    @path ||= JsonPath.new('$..date..[?(@.encoding.code == "edtf")]')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
