# frozen_string_literal: true

# Written to discover any Release tags in the cocina that is not in the migrated activerecord data
# Invoke via:
# bin/rails r -e production "AuditReleaseTagMigration.report"
class AuditReleaseTagMigration
  def self.report
    puts "item druid\n"

    [Dro, Collection].each do |klass|
      klass.where("jsonb_path_exists(administrative, '$.releaseTags.size() ? (@ > 0)')").find_each do |cocina_object|
        check_one(cocina_object)
      end
    end
  end

  def self.check_one(cocina_object)
    old_tags = cocina_object.to_cocina.administrative.releaseTags
    new_tags_count = ReleaseTag.where(druid: cocina_object.external_identifier).count
    puts cocina_object.external_identifier if new_tags_count != old_tags.size
  end
end
