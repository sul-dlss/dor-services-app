# frozen_string_literal: true

module Migrators
  # Helper methods for running Migrators::Base on individual druids and lists of druids
  class MigrationRunner
    # see README for explanation of modes
    MODES = %i[commit dryrun migrate verify].freeze
    DEFAULT_MODE = :dryrun

    # Returns a count of the druids to migrate, for the progress bar.
    # We need to get it before we start migrating, using the same logic as #druids_for to determine
    # the list of druids to migrate, without sending all the druids to each process.
    def self.druids_count_for(migrator_class:, sample:)
      specific_druids = migrator_class.druids.presence
      if specific_druids
        sample ? [sample, specific_druids.size].min : specific_druids.size
      elsif sample
        [sample, RepositoryObject.count].min
      else
        RepositoryObject.count
      end
    end

    # Returns the druids to migrate. When no specific druid list is provided by the migrator class,
    # returns a lazy enumerator that pages through the DB to avoid loading all druids into memory at once.
    def self.druids_for(migrator_class:, sample:)
      specific_druids = migrator_class.druids.presence
      if specific_druids
        sample ? specific_druids.take(sample) : specific_druids
      elsif sample
        RepositoryObject.limit(sample).pluck(:external_identifier)
      else
        RepositoryObject.select(:id, :external_identifier).find_each.lazy.map(&:external_identifier)
      end
    end

    def self.migrate_druid_list(migrator_class:, mode:, druids_slice:)
      RepositoryObject.where(external_identifier: druids_slice).map do |obj|
        migrate_repository_object(migrator_class:, obj:, mode:)
      end
    end

    # @param [Migrators::Base] migrator_class applied to obj to migrate it
    # @param [RepositoryObject] obj the RepositoryObject to migrate or verify
    # @param [Symbol] mode the mode in which to operate on obj (see MODES and DEFAULT_MODE)
    # @note If mode is `:migrate`, either the migrator class must return true for `#version?` (so that
    #  the migration runner opens/closes the object), or the objects to be migrated must already
    #  be open for versioning, otherwise `UpdateObjectService.update` will throw an error. This is not an
    #  issue in `:commit` mode, which skips the usual update services and cocina validations in favor of a plain
    #  ActiveRecord update.
    private_class_method def self.migrate_repository_object(migrator_class:, obj:, mode:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      raise ArgumentError("invalid mode #{mode}") unless MODES.include?(mode)

      migrator = migrator_class.new(obj)

      return { obj:, status: (migrator.migrate? ? 'ERROR' : 'SUCCESS') } if mode == :verify
      return { obj:, status: 'SKIPPED' } unless migrator.migrate?

      if migrator.version?
        open_version(cocina_object: obj.head_version.to_cocina_with_metadata,
                     version_description: migrator.version_description,
                     mode:)

        # reload before calling the migrator below, because the migrator may
        # work off this record or its associations, BUT it won't necessarily
        # use the same ActiveRecord version associations touched by open_version,
        # since open_version saves explicitly when needed (since it's mode aware),
        # but the migrator relies on autosave on the parent obj for persistence, which
        # happens when this migration runner updates it and closes it (in non-dry run modes).
        obj.reload
      end

      migrator.migrate # This is where the actual migration happens

      updated_cocina_object = migrator.updated_head_version_cocina_object

      if mode == :migrate
        updated_cocina_object = UpdateObjectService.update(cocina_object: updated_cocina_object,
                                                           skip_open_check: !migrator.version?)
        Publish::MetadataTransferService.publish(druid: obj.external_identifier) if migrator.publish?
        if migrator.version?
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
    rescue StandardError => e
      Rails.logger.info("#{obj.external_identifier} failed to migrate: #{e.message} -- #{e.backtrace}")
      { obj:, status: 'ERROR', exception: e }
    end

    private_class_method def self.open_version(cocina_object:, version_description:, mode:)
      return cocina_object if VersionService.open?(druid: cocina_object.externalIdentifier,
                                                   version: cocina_object.version)

      # Raise an error if the migration is trying to version an object that is not openable
      VersionService.ensure_openable!(druid: cocina_object.externalIdentifier, version: cocina_object.version)

      # This allows us to know if the object can be opened for versioning without actually opening it during a dry run
      return cocina_object if mode == :dryrun

      VersionService.open(cocina_object:, description: version_description)
    end

    private_class_method def self.close_version(cocina_object:, version_description:)
      VersionService.close(druid: cocina_object.externalIdentifier,
                           version: cocina_object.version,
                           description: version_description)
    end
  end
end
