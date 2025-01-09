# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "RelatedResourceTypes.report" > related_resource_types.csv
class RelatedResourceTypes
  # path within description
  JSON_PATH = '$.relatedResource[*].type'
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(rov.description, '#{JSON_PATH}') as values
            FROM repository_objects AS ro, repository_object_versions AS rov WHERE
            ro.head_version_id = rov.id
            AND ro.object_type = 'dro'
            AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    @types = Hash.new(0) # default value of 0
    puts "value,count\n"
    rows(SQL)

    @types.each do |value, count|
      puts "#{value},#{count}"
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    result.to_a.map do |row|
      JSON.parse(row['values']).each do |value|
        @types[value] += 1
      end
    end
  end
end
