# frozen_string_literal: true

# Generate a report on the "shape" of Cocina descriptive metadata:
#
# bin/rails r -e production "DescriptiveValueShape.report"
#
# This will output a CSV file of JSON paths that contain a string or number value,
#   where the notion of what constitutes a value is defined by Arcadia, per
#   conversation between Naomi and Arcadia 2023-06-13, and
#     https://consul.stanford.edu/display/DIGMETADATA/Complete+guide+to+Cocina+properties+and+spreadsheet+headers
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

  # QUESTIONS for Arcadia:
  #   - paths we can SKIP when looking for presence of value per object
  #       (these are useful only if there is a value:
  #         - do not count for presence of value
  #         - count occurences only when a value is present
  #       - encoding
  #       - source
  #       - standard
  #       - valueLanguage
  #       - valueScript
  #   - paths we can SKIP when looking for occurences of values per object?
  #   DECISION:  this is probably more human hours than it gains in computing hours
  #
  # SPECS:
  #
  #  2 separate types of counts to track:
  #    - presence of one or more values in an object
  #    - number of occurrences with values in objects
  #
  #  if object A has 2 subjects (with value) and object B has 3 subjects (with value):
  #    - presence of one or more subjects per object: 2:  1 for object A and 1 for object B
  #    - number of occurrences of subject: 5: 2 for object A and 3 for object B
  #
  #
  #  How to determine if a cocina property has a value:
  #
  #   DescriptiveBasicValue - (https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/descriptive_basic_value.rb)
  #     Considered to have a value if one of the following is true:
  #     - "value" has a string or integer non-blank value
  #     - "uri" has a non-blank value
  #     - "valueAt" has a non-blank value
  #     - "structuredValue", "parallelValue" or "groupedValue" descendent has populated "value" (but with nothing but these three in the path)
  #     Note that "code" with a value is only ok if we know the source -- punting for now.  Note that these are all defined as type DescriptiveValue in the openapi doc
  #
  #   DescriptiveValue - (https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/descriptive_value.rb
  #      as DescriptiveBasicValue with "appliesTo" attribute added
  #     Treat as DescriptiveBasicValue
  #
  #   Title - as DescriptiveValue
  #
  #   Contributor - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/contributor.rb
  #      name, note or identifier - only count value if these have value per DescriptiveValue
  #
  #   Event - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/event.rb
  #      any of date, contributor, location, identifier, note
  #       that have children value, uri, or valueAt or the same in (structuredValue, parallelValue, groupedValue ...) path
  #      also parallelEvent as above, e.g. parallelEvent[].date[].value
  #
  #   Form - as DescriptiveValue
  #
  #   Language - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/language.rb
  #      as DescriptiveValue with "script" added
  #
  #      treat as DescriptiveValue, but add language[].script[](.parallelValue).value as a value
  #        (parallelValue, structuredValue, groupedValue etc. can be in path)
  #
  #   Note - as DescriptiveValue
  #
  #   Identifier - as DescriptiveValue
  #
  #   Subject - as DescriptiveValue
  #
  #   Geographic - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/descriptive_geographic_metadata.rb
  #     has only "form" and "subject" as children;  treat these as you would top level subject or form
  #
  #   Purl - it's a string.  count if value is not blank
  #
  #   Access - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/descriptive_access_metadata.rb
  #     treat all immediate children (url, physicalLocation, digitalLocation, accessContact, digitalRepository, note)
  #       as DescriptiveValue
  #
  #   RelatedResource - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/related_resource.rb
  #     count it for any "top level" properties under relatedResource
  #     e.g. relatedResource[].title[].structuredValue[].value - counts as a value per recursion
  #     but relatedResource[].status - does NOT count as a value
  #
  #   AdminMetadata - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/descriptive_admin_metadata.rb
  #     https://consul.stanford.edu/display/DIGMETADATA/Complete+guide+to+Cocina+properties+and+spreadsheet+headers
  #     follow subproperties (note, event, contributor, identifier, language, metadataStandard) and use rules of indicated value, e.g.:
  #     adminMetadata.note[].value - count as value if present, but also add valueAt as a valid value
  #
  #  SUB-PROPERTIES - these should only be counted if the parent has a value per above designation
  #
  #   Standard - https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/standard.rb
  #     code <-- count as value if source has a value
  #     uri <-- count as value
  #     value <-- count as value
  #     note
  #     version
  #     source
  #
  #   (Descriptive)ValueLanguage -
  #      as Standard plus "valueScript" property, which should also count as a value (code, uri, value, valueScript)
  #
  #   Encoding - same as Standard??
  #
  #   Source - as Standard, but without "source" property:
  #     code <-- count as value if source has a value
  #     uri <-- count as value
  #     value <-- count as value
  #     note
  #     version
  #
  #   Can ignore because we're going from Marc to MODS to Cocina, not directly Marc to Cocina
  #   MarcEncodedData - treat as DescriptiveValue
  #     only present for RequestDescription
  #

end
