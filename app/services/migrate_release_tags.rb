# frozen_string_literal: true

# Migrate Release tags from the cocina to an activerecord model
# Invoke via:
# bin/rails r -e production "MigrateReleaseTags.run"
class MigrateReleaseTags
  def self.run
    [Dro, Collection].each do |klass|
      klass.where("jsonb_path_exists(administrative, '$.releaseTags.size() ? (@ > 0)')").find_each do |cocina_object|
        migrate_one(cocina_object)
      end
    end
  end

  def self.migrate_one(cocina_object)
    return if ReleaseTag.exists?(druid: cocina_object.external_identifier)

    ReleaseTag.transaction do
      cocina_object.to_cocina.administrative.releaseTags.each do |tag|
        ReleaseTag.from_cocina(druid: cocina_object.external_identifier, tag:).save!
      end
    end
  end
end
