# frozen_string_literal: true

# Reports most recent release tags.

# Invoke via:
# bin/rails r -e production "LatestReleaseTags.report"
class LatestReleaseTags
  SQL = <<~SQL.squish.freeze
    select tags.*, case when dros.id is not null then 'dro' else 'collection' end as object_type from
    (
    select distinct on (druid, released_to, what)
    druid, released_to, what, release
    from release_tags
    order by druid, released_to, what, created_at desc
    ) as tags
    left outer join dros on tags.druid=dros.external_identifier;
  SQL

  def self.report
    puts "druid,released_to,what,release,object_type\n"

    sql_result_rows = ActiveRecord::Base.connection.execute(SQL)
    sql_result_rows.each do |row|
      puts "#{row['druid']},#{row['released_to']},#{row['what']},#{row['release']},#{row['object_type']}"
    end
  end
end
