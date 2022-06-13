# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "UnstructuredDisplayNames.report"
class UnstructuredDisplayNames
  def self.report
    puts "item_druid,collection_druid\n" # rubocop:disable Rails/Output

    Dro.where("jsonb_path_exists(description, '$.contributor.name.type ? (@ == \"display\")')").find_each do |dro|
      puts "#{dro.external_identifier},#{dro.structural['isMemberOf'].first}\n" # rubocop:disable Rails/Output
    end
  end
end
