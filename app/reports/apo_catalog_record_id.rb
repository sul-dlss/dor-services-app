# frozen_string_literal: true

# Find items that are governed by the provided APO and then return all CatalogRecordIds and refresh status.
#  https://github.com/sul-dlss/dor-services-app/issues/4373
# Invoke via:
# bin/rails r -e production "ApoCatalogRecordId.report('druid:bx911tp9024')"
class ApoCatalogRecordId
  def self.report(apo_druid)
    puts %w[druid catatalogRecordId refresh].join(',')
    # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
    query = "is_governed_by_ssim:\"info:fedora/#{apo_druid}\"&objectType_ssimdv:\"item\""
    # and replace with:
    # query = "governed_by_ssim:\"#{apo_druid}\"&objectType_ssimdv:\"item\""
    druids = []
    # borrowed from bin/generate-druid-list
    loop do
      results = SolrService.query('*:*', fl: 'id', rows: 10_000, fq: query, start: druids.length, sort: 'id asc')
      break if results.empty?

      results.each { |r| druids << r['id'] }
      sleep(0.5)
    end

    druids.each do |druid|
      cocina_object = CocinaObjectStore.find(druid)
      catalog_record_ids = cocina_object.identification.catalogLinks.filter_map do |link|
        if link.catalog == 'folio'
          [link.catalog_record_id,
           link.refresh]
        end
      end.flatten
      puts ([druid] + catalog_record_ids).to_csv if catalog_record_ids.size.positive?
    end
  end
end
