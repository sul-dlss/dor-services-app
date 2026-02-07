# frozen_string_literal: true

module Migrators
  # Helper methods for running Migration::Base on individual druids and lists of druids
  class MigrationRunner
    MODES = %i[commit dryrun migrate verify].freeze
    DEFAULT_MODE = :dryrun

    def self.druids_for(migrator_class:, sample:)
      druids = migrator_class.druids.presence || RepositoryObject.pluck(:external_identifier)
      sample ? druids.take(sample) : druids
    end

    def self.migrate_druid_list(migrator_class:, mode:, druids_slice:)
      RepositoryObject.where(external_identifier: druids_slice).map do |obj|
        migrate_repository_object(migrator_class:, obj:, mode:)
      end
    end

    # @param [Migrators::Base] migrator_class applied to obj to migrate it
    # @param [RepositoryObject] obj the RepositoryObject to migrate or verify
    # @param [Symbol] mode the mode in which to operate on obj (see MODES and DEFAULT_MODE)
    private_class_method def self.migrate_repository_object(migrator_class:, obj:, mode:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      raise ArgumentError("invalid mode #{mode}") unless MODES.include?(mode)

      migrator = migrator_class.new(obj)

      return { obj:, status: (migrator.migrate? ? 'ERROR' : 'SUCCESS') } if mode == :verify
      return { obj:, status: 'SKIPPED' } unless migrator.migrate?

      current_object_version = obj.head_version.version
      if migrator.version?
        obj = open_version(cocina_object: obj, version_description: migrator.version_description, mode:)
      end

      migrator.migrate # This is where the actual migration happens

      updated_cocina_object = migrator.updated_head_version_cocina_object
      Cocina::ObjectValidator.validate(updated_cocina_object)

      if mode == :migrate
        updated_cocina_object = UpdateObjectService.update(cocina_object: updated_cocina_object,
                                                           skip_open_check: !migrator.version?)
        Publish::MetadataTransferService.publish(druid: obj.external_identifier) if migrator.publish?
        unless updated_cocina_object.version == current_object_version
          close_version(cocina_object: updated_cocina_object,
                        version_description: migrator.version_description)
        end
      elsif mode == :commit
        # For active record migrations, we need to wrap the migration in a transaction and save the object instead of
        # opening/closing versions
        obj.transaction do
          obj.save!
        end
      end
      Rails.logger.info("#{obj.external_identifier} successfully migrated")
      { obj:, status: 'SUCCESS' }
    rescue Dry::Struct::Error, Cocina::Models::ValidationError, Cocina::ValidationError => e
      Rails.logger.info("#{obj.external_identifier} failed to migrate: #{e.message} -- #{e.backtrace}")
      { obj:, status: 'ERROR', exception: e }
    end

    private_class_method def self.open_version(cocina_object:, version_description:, mode:)
      return cocina_object if VersionService.open?(druid: cocina_object.externalIdentifier)
      # Raise an error if the migration is trying to version an object that is not openable
      raise 'Cannot version' unless VersionService.can_open?(druid: cocina_object.externalIdentifier,
                                                             version: cocina_object.version)
      # This allows us to know if the object can be opened for versioning but not actually open it during a dry run
      return cocina_object if mode == :dryrun

      version_open_params = { description: version_description }
      VersionService.open(cocina_object:, **version_open_params)
    end

    private_class_method def self.close_version(cocina_object:, version_description:)
      version_close_params = { description: version_description }
      VersionService.close(druid: cocina_object.externalIdentifier,
                           version: cocina_object.version,
                           **version_close_params)
    end
  end
end
