# frozen_string_literal: true

# Generate a report on the "shape" of Cocina descriptive metadata:
#
# bin/rails r -e production "DescriptiveValueShape.report"
#
# This will output a CSV file of JSON paths that contain a string or number value,
#   where the notion of what constitutes a value is defined by Arcadia, per
#   https://github.com/sul-dlss/dor-services-app/issues/4522
#
# output of this report looks like:
# path,count
# .purl,4452
# .title[].value,4321
# .form[].type,2163
# .form[].value,1810
# .form[].source.value,1358
# .note[].value,1319
# .event[].date[].type,825
# .event[].date[].encoding.code,629
# .event[].date[].qualifier,2
# .event[].date[].structuredValue[].type,18
# .event[].date[].structuredValue[].value,18
# ...
#
# Optionally you can limit the results:
#
# - only count the first value in a record for a given path
#
# - to records that have links to the catalog
#     bin/rails r -e production "DescriptiveShape.report(catalog: 'only')"
# - to records that have no link to the catalog with:
#     bin/rails r -e production "DescriptiveShape.report(catalog: 'none')"
class DescriptiveValueShape
  # these are the outer properties we want to count if there is a value;
  # there are other properties that we only want to count if the parent has a value (e.g. Encoding)
  OUTER_PROPERTY_TO_COUNT = %w[
    title
    contributor
    event
    form
    geographic
    language
    note
    identiier
    subject
    access
    relatedResource
    marcEncodedData
    adminMetadata
    valueAt
    purl
  ].freeze

  def self.report(catalog: 'all')
    new(catalog).report
  end

  def initialize(catalog)
    @catalog = catalog
    @result = Hash.new(0)
  end

  def report
    Dro.find_each do |cocina_object|
      has_catalog_link = cocina_object.identification['catalogLinks'].present?

      next if @catalog == 'none' && has_catalog_link

      next if @catalog == 'only' && !has_catalog_link

      trace(cocina_object.description)
    end
    output
  end

  private

  def trace(obj, path = '')
    case obj
    when Array
      trace_array(obj, path)
    when Hash
      trace_hash(obj, path)
    else
      @result[path] += 1 if obj.present?
    end
  end

  def trace_array(obj, path)
    obj.each do |item|
      trace(item, "#{path}[]") if item.present?
    end
  end

  def trace_hash(obj, path)
    obj.each do |key, value|
      if path.blank? && OUTER_PROPERTY_TO_COUNT.include?(key)
        trace(value, "#{path}.#{key}") if property_countable?(key, value)
      elsif value.present?
        # we are at a nested level; continue only if a value is present
        trace(value, "#{path}.#{key}")
      end
    end
    # value, uri, valueAt
    # if structuredValue, parallelValue or groupedValue, recurse
  end

  def property_countable?(key, value)
    return false if value.blank?

    case key
    when %w[title form note identifier subject].include?(key)
      value.any? { |descriptive_basic_value_obj| countable?(descriptive_basic_value_obj) }
    when 'contributor'
      # only count value if direct children properties of name, note, or identifier have value per DescriptiveBasicValue
      value.any? do | single_contributor_obj |
        single_contributor_obj.each do |contributor_key, contributor_value|
          return false unless %w[name note identifier].include?(contributor_key)

          countable?(contributor_value)
        end
      end
    when 'event'
      # only count value if
      # - direct children properties of date, contributor, location, identifier, note have value per DescriptiveBasicValue
      # - direct child parallelEvent as above, e.g. parallelEvent[].date[].value
      value.any? do | single_event_obj |
        single_event_obj.each do |event_key, event_value|
          return false unless %w[date contributor location identifier note].include?(event_key)

          countable?(event_value)
        end
      end

    when 'purl'
      true if value.present? # purl is a String and the cocina has been validated
    else
      false
    end
  end

  SIMPLE_VALUE_PROPERTIES = %w[value uri valueAt].freeze
  COMPLEX_VALUE_PROPERTIES = %w[structuredValue parallelValue groupedValue].freeze

  # a cocina DescriptiveBasicValue is countable if it has:
  #  - a child property of "value", "uri" or "valueAt" with a non-blank value (all of these are Strings or Integers)
  #  - a child property of "structuredValue", "parallelValue" or "groupedValue"
  #      with a child or descendent property of "value" or "uri" with a non-blank value BUT
  #      the descendent path can only have "structuredValue" or "parallelValue" between it and the child with the value
  def countable?(descriptive_basic_value)
    return false unless descriptive_basic_value.is_a?(Hash)

    descriptive_basic_value.each do |key, value|
      return true if SIMPLE_VALUE_PROPERTIES.include?(key) && value.present?
      return countable?(value) if COMPLEX_VALUE_PROPERTIES.include?(key)
    end
  end


  def output
    puts 'path,count'
    @result.each do |path, count|
      puts "#{path},#{count}"
    end
  end
end
