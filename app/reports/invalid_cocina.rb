# frozen_string_literal: true

require 'csv'

# Find items that are NOT file content_type ('https://cocina.sul.stanford.edu/models/object')
#  and see if they pass the FileHierarchyValidator validator.  Write those that fail to CSV.
#  Used to find non-file type objects that may have file hiearchy.
#  https://github.com/sul-dlss/dor-services-app/issues/4360
# Invoke via:
# bin/rails r -e production "InvalidCocina.report"
class InvalidCocina
  def self.report
    output_file = 'tmp/invalid_cocina_report.csv'
    num_invalid = 0

    CSV.open(output_file, 'w') do |csv|
      csv << %w[item_druid content_type]
      dros = Dro.select(:external_identifier, :content_type).where.not(content_type: 'https://cocina.sul.stanford.edu/models/object')
      num_dros = dros.size
      puts "Found #{num_dros} objects that are NOT file type"
      dros.each_with_index do |dro, i|
        druid = dro.external_identifier
        puts "#{i + 1} of #{num_dros} : #{druid}"
        cocina_object = CocinaObjectStore.find(druid)
        unless Cocina::FileHierarchyValidator.new(cocina_object).valid?
          num_invalid += 1
          csv << [druid, dro.content_type]
        end
      end
      puts "Found #{num_invalid} invalid out of #{num_dros}"
      puts "Report written to #{output_file}"
    end
  end
end
