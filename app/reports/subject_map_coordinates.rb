# frozen_string_literal: true

# Report all map coordinates values in subjects
# Invoke via:
# bin/rails r -e production "SubjectMapCoordinates.report"
class SubjectMapCoordinates
  # Finds an object like this: https://argo.stanford.edu/view/druid:bb051ch9980
  # "description": {
  #   "subject": [
  #      {
  #           "value": "E 13°59'00\"--E 34°28'00\"/S 22°07'00\"--S 35°39'00\"",
  #           "type": "map coordinates"
  #       }
  #   ],

  SUBJECT_PATH = JsonPath.new('$..subject[?(@.type == "map coordinates")].value')

  def self.report
    puts "item_druid|collection_druid|coordinates\n"

    Dro.where("jsonb_path_exists(description, '$.**.subject.type ? (@ ==  \"map coordinates\")')").find_each do |dro|
      druid = dro.external_identifier
      collection = dro.structural['isMemberOf'].join(' ')
      coordinates = SUBJECT_PATH.on(dro.description.to_json).join('|')

      puts "#{druid}|#{collection}|#{coordinates}\n"
    end
  end
end
