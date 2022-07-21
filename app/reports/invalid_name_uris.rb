# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidNameUris.report"
class InvalidNameUris
  def self.report
    puts "item_druid,collection_druid,catkey,value\n"

    Dro.where("jsonb_path_exists(description, '$.contributor.name.uri ? (@ like_regex \"^(?!https?://).*$\")')").or(
      Dro.where("jsonb_path_exists(description, '$.contributor.name.uri ? (@ like_regex \"^.*\.html$\")')")
    ).find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    puts "#{dro.external_identifier},#{collection_id},#{catkey},#{values}\n"
  end

  private

  attr_reader :dro

  # locate the date nodes within the structuredValue
  def path
    @path ||= JsonPath.new('$..contributor..name..uri')
  end

  def values
    path.on(dro.description.to_json)
        .filter { |node| node.end_with?('.html') || !%r{^https?://}.match?(node) }
        .join(';')
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
