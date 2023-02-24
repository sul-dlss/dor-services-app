# frozen_string_literal: true

require 'csv'

# Find items that are goverened by the provided APO and then return all catkeys and refresh status.
#  https://github.com/sul-dlss/dor-services-app/issues/4373
# Invoke via:
# bin/rails r -e production "ApoCatkey.report('druid:bx911tp9024')"
class ApoCatkey
  def self.report(apo_druid)
    output_file = 'tmp/etd_catkey_report.csv'

    CSV.open(output_file, 'w') do |csv|
      csv << %w[druid catkey refresh]
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
        catkeys = cocina_object.identification.catalogLinks.filter_map { |link| [link.catalogRecordId, link.refresh] if link.catalog == 'symphony' }.flatten
        csv << ([druid] + catkeys) if catkeys.size.positive?
      end
      puts "Report written to #{output_file}"
    end
  end
end