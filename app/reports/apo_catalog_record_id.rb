# frozen_string_literal: true

# Find items that are governed by the provided APO and then return all CatalogRecordIds and refresh status.
#  https://github.com/sul-dlss/dor-services-app/issues/4373
# Invoke via:
# bin/rails r -e production "ApoCatalogRecordId.report('druid:bx911tp9024')"
class ApoCatalogRecordId
  def self.report(apo_druid)
    puts %w[druid catatalogRecordId refresh].to_csv

    RepositoryObject.dros.currently_governed_by_admin_policy(apo_druid).each do |druid|
      cocina_object = CocinaObjectStore.find(druid)
      catalog_record_ids = cocina_object.identification.catalogLinks.filter_map do |link|
        if link.catalog == 'folio'
          [link.catalog_record_id,
           link.refresh]
        end
      end.flatten
      puts ([druid] + catalog_record_ids).to_csv if catalog_record_ids.any?
    end
  end
end
