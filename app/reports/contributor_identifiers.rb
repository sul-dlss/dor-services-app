# frozen_string_literal: true

# Find items that have contributors with identifiers
# Invoke via:
# bin/rails r -e production "ContributorIdentifiers.report"
class ContributorIdentifiers
  def self.report
    puts "item_druid,collection_druid,catalogRecordId,identifier\n"

    Dro.where("jsonb_path_exists(description, '$.contributor.identifier.value')").find_each do |dro|
      druid = dro.external_identifier
      collection = dro.structural['isMemberOf'].first
      catalog_record_id = dro.identification['catalogLinks'].first&.fetch('catalogRecordId')

      dro.description.fetch('contributor').map do |contributor|
        contributor['identifier'].map do |identifier|
          puts "#{druid},#{collection},#{catalog_record_id},#{identifier['value']}\n"
        end
      end
    end
  end
end
