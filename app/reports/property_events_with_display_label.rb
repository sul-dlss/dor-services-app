# frozen_string_literal: true

# Generate a report of DROs that have at leaste one event with a displayLabel
#
# bin/rails r -e production "PropertyEventsWithDisplayLabel.report"
#
class PropertyEventsWithDisplayLabel
  def self.report
    puts 'purl,title,collection name,APO'

    Dro.where("jsonb_path_exists(description, '$.event.displayLabel')").find_each do |dro|
      purl = dro.description['purl']
      collection = dro.structural['isMemberOf'].first
      collection_name = Collection.find_by(external_identifier: collection)&.label
      next if dro.identification['catalogLinks'].pluck('catalog').include? 'folio'

      puts "#{purl},#{dro.label},#{collection_name},#{dro.administrative['hasAdminPolicy']}\n"
    end
  end
end
