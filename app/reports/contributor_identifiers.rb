# frozen_string_literal: true

# Find items that have contributors with identifiers
# Invoke via:
# bin/rails r -e production "ContributorIdentifiers.report"
class ContributorIdentifiers
  def self.report
    puts "item_druid,collection_druid,catalogRecordId,identifier\n"

    RepositoryObject.dros.where(head_version: "jsonb_path_exists(description, '$.contributor.identifier.value')").find_each do |dro|
      druid = dro.external_identifier
      head_version = dro.head_version
      collection = head_version.structural['isMemberOf'].first
      catalog_record_id = head_version.identification['catalogLinks'].first&.fetch('catalogRecordId')

      head_version.description.fetch('contributor').map do |contributor|
        contributor['identifier'].map do |identifier|
          puts [druid, collection, catalog_record_id, identifier['value']].to_csv
        end
      end
    end
  end
end
