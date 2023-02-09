# frozen_string_literal: true

require 'csv'

# rubocop:disable Metrics/BlockLength
# see https://github.com/sul-dlss/dor-services-app/issues/4327
namespace :catkeys do
  desc 'Lookup catkey from barcode and create a new output file that includes the catkey'
  # requires input file of CSV with three columns with lowercase headers: druid,barcode,title
  # writes out a new CSV file with the same columsn but adds the catkey if available
  # rake catkeys:lookup['tmp/only-barcodes-with-title.csv']
  task :lookup, %i[input_file] => :environment do |_t, args|
    input_file = args[:input_file]
    raise 'input_file not specified' unless input_file

    output_file = input_file.gsub('.csv', '_output.csv')

    rows = CSV.parse(File.read(input_file), headers: true)
    num_rows = rows.size

    puts "Input file: #{input_file}"
    puts "Output file: #{output_file}"
    puts "Num rows: #{num_rows}"
    num_no_catkey = 0
    num_barcode_not_found = 0
    num_druid_not_found = 0

    CSV.open(output_file, 'w') do |csv|
      csv << %w[druid barcode title catkey sdr_title sw_title]
      rows.each_with_index do |row, i|
        druid = row['druid']
        druid_with_prefix = druid.start_with?('druid:') ? druid : "druid:#{druid}"
        barcode = row['barcode']
        title = row['title']
        catkey = nil
        sdr_title = ''
        sw_title = ''
        puts "#{i + 1} of #{num_rows} : #{druid}"
        begin
          catkey = SymphonyReader.new(barcode:).fetch_catkey
          num_no_catkey += 1 unless catkey
          cocina_object = CocinaObjectStore.find(druid_with_prefix)
          sdr_title = Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title)
          sw_json = JSON.parse(Faraday.get("https://searchworks.stanford.edu/view/#{catkey}.json").body)
          sw_title = sw_json['response']&.dig('document')&.dig('title_display')
        rescue SymphonyReader::NotFound
          num_barcode_not_found += 1
        rescue CocinaObjectStore::CocinaObjectNotFoundError
          num_druid_not_found += 1
        ensure
          csv << [druid, barcode, title, catkey, sdr_title, sw_title]
        end
      end
    end

    puts "Num rows: #{num_rows}; num no catkey returned: #{num_no_catkey}; num no barcode found: #{num_barcode_not_found}, num no druid found: #{num_druid_not_found}"
    puts "Results written to: #{output_file}"
  end

  desc 'Add catkey to cocina object given csv with druids and catkeys'
  # requires input file of CSV with at least two columns with lowercase headers: druid,catkey
  # looks up each cocina object by druid, adds the catkey to the identification with refresh=true
  # skips adding if the catkey is already in the record
  # rake catkeys:add['tmp/only-barcodes-with-title_output.csv']
  task :add, %i[input_file] => :environment do |_t, args|
    input_file = args[:input_file]
    raise 'input_file not specified' unless input_file

    rows = CSV.parse(File.read(input_file), headers: true)
    num_rows = rows.size

    puts "Input file: #{input_file}"
    puts "Num rows: #{num_rows}"
    druid_not_found_list = []
    catkey_exists_list = []
    cannot_version_list = []
    cocina_validation_error_list = []
    other_error_list = []

    rows.each_with_index do |row, i|
      druid = row['druid']
      druid_with_prefix = druid.start_with?('druid:') ? druid : "druid:#{druid}"
      catkey = row['catkey']
      puts "#{i + 1} of #{num_rows} : #{druid}"
      begin
        cocina_object = CocinaObjectStore.find(druid_with_prefix)
        catkey_exists = cocina_object.identification&.catalogLinks&.any? { |link| link.catalog == 'symphony' && link.catalogRecordId == catkey }
        if catkey_exists
          catkey_exists_list << druid
        else
          updated_cocina_object = cocina_object.dup
          catalog_link = Cocina::Models::CatalogLink.new(catalog: 'symphony', refresh: true, catalogRecordId: catkey)
          updated_cocina_object.identification.catalogLinks << catalog_link
          UpdateObjectService.update(updated_cocina_object, skip_lock: true)
          version_open_params = { significance: 'admin', description: 'Add missing catkey to cocina via barcode lookup to symphony' }
          # if this is an existing versionable object, open and close it, which will start accessionWF
          if VersionService.can_open?(updated_cocina_object)
            opened_cocina_object = VersionService.open(updated_cocina_object, **version_open_params)
            VersionService.close(opened_cocina_object)
          # if this is an existing accessioned object that is currently open, just close it
          elsif VersionService.open?(updated_cocina_object)
            VersionService.close(updated_cocina_object, **version_open_params)
          else
            cannot_version_list << druid
          end
        end
      rescue Cocina::ValidationError
        cocina_validation_error_list << druid
      rescue CocinaObjectStore::CocinaObjectNotFoundError
        druid_not_found_list << druid
      rescue StandardError
        other_error_list << druid
      end
    end

    puts "Num rows: #{num_rows}"
    puts "Num catkey already exists in record: #{catkey_exists_list.size}; num no druid found: #{druid_not_found_list.size}"
    puts "Num other errors: #{other_error_list.size}; num cannot version: #{cannot_version_list.size}; num cocina validation error: #{cocina_validation_error_list.size}"
    puts "Catkey exists: #{catkey_exists_list.join(', ')}"
    puts "Cocina validation error: #{cocina_validation_error_list.join(', ')}"
    puts "Cannot version: #{cannot_version_list.join(', ')}"
    puts "Druid not found: #{druid_not_found_list.join(', ')}"
    puts "Other errors: #{other_error_list.join(', ')}"
  end
end
# rubocop:enable Metrics/BlockLength
