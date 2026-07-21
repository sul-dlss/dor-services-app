# frozen_string_literal: true

# Report dro objects with occurrences of a property.
#
# Invoke via: `bin/rails r -e production PropertyExistenceDros.report`
class PropertyExistenceDros
  # This name is misleading: it can be any valid JSON path desired, not just a
  # single property, e.g. `contributor[*].type`, `groupedValue`,
  # `relatedResource.**.relatedResource`
  PROPERTIES = [
    'valueLanguage.note',
    'valueScript.note',
    'source.note',
    'standard.note',
    'encoding.note',
    'identifier.note',
    'identifier.identifier',
    'note.note',
    'note.identifier',
    'relatedResource.**.relatedResource'
  ].freeze

  def self.report
    puts 'item_druid,folio_instance_hrid,collection_druid,collection_name'

    ActiveRecord::Base.connection.execute(property_query).to_a.each do |row|
      next if row.blank?

      collection_head_version = RepositoryObject.collections.find_by(external_identifier: row['collection_druid'])&.head_version
      if collection_head_version&.has_cocina?
        collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
      end

      puts [
        row['item_druid'],
        row['folio_instance_hrid'],
        row['collection_druid'],
        collection_name
      ].to_csv
    end
  end

  def self.property_queries
    PROPERTIES.map do |property|
      "jsonb_path_exists(rov.description, 'strict $.**.#{property} ? (@.size() > 0)')"
    end
  end

  def self.property_query
    <<~SQL.squish.freeze
      SELECT ro.external_identifier as item_druid,
             jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
             jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as folio_instance_hrid,
             jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid
             FROM repository_objects AS ro, repository_object_versions AS rov
             WHERE ro.head_version_id = rov.id
             AND ro.object_type = 'dro'
             AND (#{property_queries.join(' OR ')})
    SQL
  end
end
