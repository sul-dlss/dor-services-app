# frozen_string_literal: true

# Generate a report on the "shape" of Cocina descriptive metadata:
#
# bin/rails r -e production "DescriptiveShape.report"
#
# This will output a CSV file of JSON paths that contain a string or number value:
#
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
# .event[].note[].type,219
# .event[].note[].value,219
# .event[].note[].source.value,203
# .event[].location[].code,204
# .event[].location[].source.code,204
# .event[].date[].value,816
# .event[].location[].value,196
# .title[].note[].type,161
# ...
#
# Optionally you can limit the results:
# - to records that have links to the catalog
#     bin/rails r -e production "DescriptiveShape.report(catalog: 'only')"
# - to records that have no link to the catalog with:
#     bin/rails r -e production "DescriptiveShape.report(catalog: 'none')"
# - to indicate presence or absence of a path for a record, instead of the counts:
#     bin/rails r -e production "DescriptiveShape.report(count: 'presence')"
#      (note that 'all' is the default)
#     bin/rails r -e production "DescriptiveShape.report(count: 'all')"
# - combining both switches:
#     bin/rails r -e production "DescriptiveShape.report(catalog: 'only', count: 'presence')"
class DescriptiveShape
  def self.report(catalog: 'all', count: 'all')
    # NOTE:  initialize cannot take any arguments as it is a rails runner
    instance = new
    instance.catalog = catalog
    instance.count = count
    instance.report
  end

  attr :catalog, :count

  # NOTE:  initialize cannot take any arguments as it is a rails runner
  #       so we have to set the instance variables after initialization
  def initialize
    @shape = Hash.new(0)
  end

  def report
    Dro.find_each do |obj|
      has_catalog_link = obj.identification['catalogLinks'].present?

      next if @catalog == 'none' && has_catalog_link

      next if @catalog == 'only' && !has_catalog_link

      trace(obj.description)
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
    when present?
      if count == 'presence' &&
         @shape[path] == 0 &&
         path.end_with?('value', 'valueAt', 'uri', 'code')
        @shape[path] = 1
      else # count == 'all'
        @shape[path] += 1
      end
    end
  end

  def trace_array(obj, path)
    obj.each do |item|
      trace(item, "#{path}[]") if item.present?
    end
  end

  def trace_hash(obj, path)
    obj.each do |key, value|
      trace(value, "#{path}.#{key}") if value.present?
    end
  end

  def output
    puts 'path,count'
    @shape.each do |path, count|
      puts "#{path},#{count}"
    end
  end
end
