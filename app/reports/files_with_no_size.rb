# frozen_string_literal: true

# Look for Files that don't have a size attribute
# Invoke via:
# bin/rails r -e production "FilesWithNoSize.report"
class FilesWithNoSize
  JSON_PATH = '$.contains[*].structural.contains[*]'
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_array_length(jsonb_path_query_array(rov.structural, '#{JSON_PATH}')) !=
            jsonb_array_length(jsonb_path_query_array(rov.structural, '#{JSON_PATH}.size'))
  SQL

  def self.report
    puts "item_druid\n"
    result = ActiveRecord::Base.connection.execute(SQL)

    result.each do |row|
      puts row.fetch('external_identifier')
    end
  end
end
