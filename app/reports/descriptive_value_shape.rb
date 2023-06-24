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
  # NOTE:  we are dealing with cocina so we expect symbol keys

  # these are the outer properties we want to count if there is a value;
  # there are other properties that we only want to count if the parent has a value (e.g. Encoding)
  OUTER_PROPERTY_TO_COUNT = %i[
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

  # properties we want to count as a vanilla DescriptiveBasicValue - no special handling required
  DESCRIPTIVE_BASIC_VALUE_PROPERTIES = %i[
    title
    form
    note
    identifier
    subject
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
        trace(value, "#{path}.#{key}") if countable_property?(key, value)
      elsif value.present?
        # we are at a nested level; continue only if a value is present
        trace(value, "#{path}.#{key}")
      end
    end
    # value, uri, valueAt
    # if structuredValue, parallelValue or groupedValue, recurse
  end

  def countable_property?(property, value)
    return false if value.blank?

    case property
    when ->(property) { DESCRIPTIVE_BASIC_VALUE_PROPERTIES.include?(property) }
      countable?(value)
    when :contributor
      value.each do |key, sub_property_values|
        return true if %i[name note identifier].include?(key) && sub_property_values.any? { |val| countable?(val) }
      end
      false
    when :event
      value.each do |key, sub_property_values|
        return true if %i[date contributor location identifier note].include?(key) && sub_property_values.any? { |val| countable?(val) }

        return true if key == :parallelEvent && sub_property_values.any? { |val| countable_property?(:event, val) }
      end
      false
    when :language
      return true if countable?(value)

      value.any? { |key, sub_property_values| key == :script && countable?(sub_property_values) }
    when :geographic
      value.each do |key, sub_property_values|
        return true if %i[form subject].include?(key) && sub_property_values.any? { |val| countable?(val) }
      end
      false
    when :purl
      true if value.present? # purl is a String and the cocina has been validated
    when :access
    when :adminMetadata
    when :relatedResource
    else
      false
    end
  end

  SIMPLE_VALUE_PROPERTIES = %i[value uri valueAt].freeze
  COMPLEX_VALUE_PROPERTIES = %i[structuredValue parallelValue groupedValue].freeze

  # a cocina DescriptiveBasicValue is countable if it has:
  #  - a child property of "value", "uri" or "valueAt" with a non-blank value (all of these are Strings or Integers)
  #  - a child property of "structuredValue", "parallelValue" or "groupedValue"
  #      with a child or descendent property of "value" or "uri" with a non-blank value BUT
  #      the descendent path can only have "structuredValue" or "parallelValue" between it and the child with the value
  def countable?(descriptive_basic_value)
    if descriptive_basic_value.is_a?(Hash)
      descriptive_basic_value.each do |key, value|
        return true if SIMPLE_VALUE_PROPERTIES.include?(key) && value.present?
        return countable?(value) if COMPLEX_VALUE_PROPERTIES.include?(key) && value.present?
      end
    elsif descriptive_basic_value.is_a?(Array)
      descriptive_basic_value.each do |val|
        return true if countable?(val) && val.present?
      end
    end

    false
  end

  def output
    puts 'path,count'
    @result.each do |path, count|
      puts "#{path},#{count}"
    end
  end
end
