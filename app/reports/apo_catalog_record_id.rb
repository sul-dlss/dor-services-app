# frozen_string_literal: true

# Find items that are goverened by the provided APO and then return all CatalogRecordIds and refresh status.
#  https://github.com/sul-dlss/dor-services-app/issues/4373
# Invoke via:
# bin/rails r -e production "ApoCatalogRecordId.report('druid:bx911tp9024')"
class ApoCatalogRecordId
  def self.report(apo_druid)
    output_file = 'tmp/etd_catalogRecordId_report.csv'

    CSV.open(output_file, 'w') do |csv|
      csv << %w[druid catatalogRecordId refresh]
      query = "is_governed_by_ssim:\"info:fedora/#{apo_druid}\"&objectType_ssim:\"item\""
      druids = []
      # borrowed from bin/generate-druid-list
      loop do
        results = SolrService.query('*:*', fl: 'id', rows: 10000, fq: query, start: druids.length, sort: 'id asc')
        break if results.empty?

        results.each { |r| druids << r['id'] }
        sleep(0.5)
      end

      num_dros = druids.size
      puts "Found #{num_dros} objects that are governed by APO #{apo_druid}"
      druids.each_with_index do |druid, i|
        puts "#{i + 1} of #{num_dros} : #{druid}"
        cocina_object = CocinaObjectStore.find(druid)
        catalog_record_ids = cocina_object.identification.catalogLinks.filter_map { |link| [link.catalog_record_id, link.refresh] if link.catalog == 'folio' }.flatten
        csv << ([druid] + catalog_record_ids) if catalog_record_ids.size.positive?
      end
      puts "Report written to #{output_file}"
    end
  end
end
