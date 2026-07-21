# frozen_string_literal: true

# Generate a report of DROs that have at leaste one event with a displayLabel
#
# bin/rails r -e production "PropertyEventsWithDisplayLabel.report"
#
class PropertyEventsWithDisplayLabel
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as item_druid,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query_array(rov.description, '$.event.displayLabel') as displayLabels,
           jsonb_path_query_first(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') as catalogRecordId
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '$.event.displayLabel');
  SQL

  def self.report
    puts "item_druid,title,collection,catalog_record_id,display_labels\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_head_version = RepositoryObject.collections.find_by(external_identifier: row['collection_druid'])&.head_version
      if collection_head_version&.has_cocina?
        collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
      end
      display_labels = JSON.parse(row['displaylabels']).map { |label| "\"#{label}\"" }.join(';')

      [
        row['item_druid'],
        (row['structured_title'] || row['title'])&.delete("\n"),
        collection_name,
        row['catalogrecordid'],
        display_labels
      ].to_csv
    end
  end
end
