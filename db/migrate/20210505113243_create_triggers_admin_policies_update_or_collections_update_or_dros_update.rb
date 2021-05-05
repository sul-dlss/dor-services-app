# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersAdminPoliciesUpdateOrCollectionsUpdateOrDrosUpdate < ActiveRecord::Migration[5.2]
  def up
    create_trigger("admin_policies_after_update_row_tr", :generated => true, :compatibility => 1).
        on("admin_policies").
        after(:update) do
      "INSERT INTO admin_policy_versions(admin_policy_id, druid, label, version, administrative, description, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.label, NEW.version), NULLIF(OLD.version, NEW.version), NUllIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), OLD.created_at, OLD.updated_at);"
    end

    create_trigger("collections_after_update_row_tr", :generated => true, :compatibility => 1).
        on("collections").
        after(:update) do
      "INSERT INTO collection_versions(collection_id, druid, content_type, label, version, access, administrative, description, identification, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), OLD.created_at, OLD.updated_at);"
    end

    create_trigger("dros_after_update_row_tr", :generated => true, :compatibility => 1).
        on("dros").
        after(:update) do
      "INSERT INTO dro_versions(dro_id, druid, content_type, label, version, access, administrative, description, identification, structural, geographic, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), NULLIF(OLD.structural, NEW.structural), NULLIF(OLD.geographic, NEW.geographic), OLD.created_at, OLD.updated_at);"
    end
  end

  def down
    drop_trigger("admin_policies_after_update_row_tr", "admin_policies", :generated => true)

    drop_trigger("collections_after_update_row_tr", "collections", :generated => true)

    drop_trigger("dros_after_update_row_tr", "dros", :generated => true)
  end
end
