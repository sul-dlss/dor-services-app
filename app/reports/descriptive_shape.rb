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
class DescriptiveShape
  def self.report(catalog: 'all')
    new(catalog).report
  end

  def initialize(catalog)
    @catalog = catalog
    @shape = Hash.new(0)
  end

  def report
    RepositoryObject.dros.find_each do |obj|
      has_catalog_link = obj.head_version.identification['catalogLinks'].present?

      next if @catalog == 'none' && has_catalog_link

      next if @catalog == 'only' && !has_catalog_link

      trace(obj.head_version.description)
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
      @shape[path] += 1 if obj.present?
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
