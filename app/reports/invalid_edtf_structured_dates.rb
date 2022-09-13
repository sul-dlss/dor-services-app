# frozen_string_literal: true

# This report is incomplete, as it only finds edtf dates with structuredValues, per its spec
#   (https://github.com/sul-dlss/dor-services-app/issues/4218)
#  NOTE:  this report DOES find the structuredValues with value level encoding on only ONE
#   of the values;  invalid_edtf_dates.rb does NOT find those cases.
#
# Invoke via:
# bin/rails r -e production "InvalidEdtfStructuredDates.report"
class InvalidEdtfStructuredDates
  # structuredValue where entire date is EDTF encoded; example =
  #   {
  #     event: [
  #       {
  #         date: [
  #           {
  #             structuredValue: [
  #               { value: '123', type: 'start'},
  #               { value: '456', type: 'end'}
  #             ],
  #             encoding: { code: 'edtf' }
  #           }
  #         ]
  #       }
  #     ]
  #   }
  STRUCTURE_ENCODING_JSON_PATH = JsonPath.new('$..date[?(@.encoding.code == "edtf")]')

  # structuredValue where value has encoding indicated as EDTF; example =
  #   {
  #     event: [
  #       {
  #         date: [
  #           {
  #             structuredValue: [
  #               { value: '0123', type: 'start', encoding: { code: 'edtf' } },
  #               { value: '0456', type: 'end' }
  #             ]
  #           }
  #         ]
  #       }
  #     ]
  #   }
  VALUE_ENCODING_JSON_PATH = JsonPath.new('$..date..structuredValue.[?(@.encoding.code == "edtf")]')

  def self.report
    puts "item_druid,catkey,collection_druid,invalid_values,reason\n"

    Dro.where("jsonb_path_exists(description, '$.**.date.**.encoding.code ? (@ == \"edtf\")')").find_each do |dro|
      new(dro:).report
    end
  end

  def initialize(dro:)
    @dro = dro
  end

  def report
    output_invalid_with_structure_encodings
    output_single_value_edtf_encoding
  end

  private

  attr_reader :dro

  # outputs structuredValue with sibling encoding of edtf and invalid edtf values
  def output_invalid_with_structure_encodings
    bad_values = []
    STRUCTURE_ENCODING_JSON_PATH.on(dro.description.to_json).each do |date|
      date['structuredValue'].each do |structured_value|
        bad_values << structured_value['value'] unless valid_edtf?(structured_value['value'])
      end
    end
    return if bad_values.blank?

    first_columns = "#{dro.external_identifier},#{catkey},#{collection_id}"
    puts "#{first_columns},#{bad_values.join(';')},entire date edtf - invalid value\n"
  end

  # outputs edtf value from a date with structuredValue where only one of the two expected child values is indicated edtf
  def output_single_value_edtf_encoding
    dates_with_value_encodings = VALUE_ENCODING_JSON_PATH.on(dro.description.to_json)
    # FIXME:  this can be incorrect if there are multiple dates matching the json path
    #  it is hoped that case is rare.
    return if dates_with_value_encodings.size != 1

    first_columns = "#{dro.external_identifier},#{catkey},#{collection_id}"
    single_value = dates_with_value_encodings.first['value']
    puts "#{first_columns},#{single_value},single date encoded edtf within structuredValue\n" if single_value.present?
  end

  def valid_edtf?(date_value)
    # edtf! raises error if it can't parse it
    Date.edtf!(date_value) ? true : false
  rescue ArgumentError
    # NOTE: the upstream EDTF implementation in the `edtf` gem does not
    #       allow a valid pattern that we use (possibly because only level
    #       0 of the spec was implemented?):
    #
    # * Y-20555
    #
    # So we catch the false positives from the upstream gem and allow
    # this pattern to validate
    /\AY-?\d{5,}\Z/.match?(date_value)
  end

  def collection_id
    dro.structural['isMemberOf'].first
  end

  def catkey
    dro.identification['catalogLinks'].find { |link| link['catalog'] == 'symphony' }&.fetch('catalogRecordId')
  end
end
