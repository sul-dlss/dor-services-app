# frozen_string_literal: true

module Migrators
  # Performs migration on a RepositoryObject given a migrator class.
  class MigrationRunner
    # see README for explanation of modes
    MODES = %i[dryrun migrate].freeze
    DEFAULT_MODE = :dryrun

    Result = Struct.new(:id, :external_identifier, 'version', :status, :exception)

    # @return [Array<Result>] results for the migration attempts
    def self.migrate_druid_list(migrator_class:, mode:, druids_slice:)
      druids_slice.each_slice(15).flat_map do |druids_slice_batch|
        RepositoryObject
          .includes(:versions, :head_version, :last_closed_version, :opened_version)
          .where(external_identifier: druids_slice_batch)
          .find_each
          .flat_map { |repository_object| new(migrator_class:, repository_object:, mode:).call }
      end
    end

    # @param [Migrators::Base] migrator_class
    # @param [RepositoryObject] repository_object the RepositoryObject to migrate
    # @param [Symbol] mode the mode in which to operate on repository_object (see MODES and DEFAULT_MODE)
    def initialize(migrator_class:, repository_object:, mode:)
      @migrator_class = migrator_class
      @repository_object = repository_object
      @mode = mode

      raise ArgumentError, "invalid mode #{mode}" unless MODES.include?(mode)
      return unless migrator_class.dryrun_only? && mode != :dryrun

      raise ArgumentError,
            "migrator #{migrator_class} is dryrun-only and cannot be run in mode #{mode}"
    end

    def call
      if migrator_class.migration_tag &&
         AdministrativeTags.exist?(identifier: repository_object.external_identifier,
                                   tag: migrator_class.migration_tag)
        return [Result.new(status: 'SKIPPED', **result_id_attrs)]
      end

      runner_class = migrator_class.cocina_update? ? CocinaUpdateRunner : CommitRunner
      runner_class.new(migrator_class:, repository_object:, mode:).call
    end

    private

    attr_reader :migrator_class, :repository_object, :mode

    def result_id_attrs
      { id: repository_object.id, external_identifier: repository_object.external_identifier }
    end

    # Base class for migration runners.
    class BaseRunner
      def initialize(migrator_class:, repository_object:, mode:)
        @migrator_class = migrator_class
        @repository_object = repository_object
        @mode = mode
        @open_before_migration = version_service.open?
      end

      private

      attr_reader :migrator_class, :repository_object, :mode

      # @return [Integer, nil] the opened version number if the object is open, nil otherwise
      def opened_version
        @opened_version ||= repository_object.opened_version&.version
      end

      # @return [Integer, nil] the last closed version number if the object has been closed, nil otherwise
      def last_closed_version
        @last_closed_version ||= repository_object.last_closed_version&.version
      end

      # @return [Integer] the head version number
      def head_version
        @head_version ||= repository_object.head_version.version
      end

      def version_service
        @version_service ||= VersionService.new(druid:, version: repository_object.head_version.version,
                                                repository_object:)
      end

      def open_before_migration?
        @open_before_migration
      end

      def open_version!
        # This allows us to know if the object can be opened for versioning without actually opening it during a dry run
        if dryrun?
          # Raise an error if the migration is trying to version an object that is not openable
          version_service.ensure_openable!(assume_accessioned: false)
        else
          version_service.open(cocina_object: repository_object.head_version.to_cocina,
                               description: migrator_class.version_description,
                               assume_accessioned: false)
        end
      end

      def result_id_attrs
        { id: repository_object.id, external_identifier: repository_object.external_identifier }
      end

      def druid
        repository_object.external_identifier
      end

      def dryrun?
        mode == :dryrun
      end

      def to_model_hash(repository_object_version, version: nil)
        model_hash = repository_object_version.to_h.stringify_keys
        model_hash['version'] = version if version
        model_hash.freeze
      end

      def migrate_model_hash(model_hash:, valid:)
        migrator_class.new(model_hash: model_hash.deep_dup,
                           opened_version: model_hash['version'] == opened_version,
                           last_closed_version: model_hash['version'] == last_closed_version,
                           head_version: model_hash['version'] == head_version,
                           valid:).migrate
      end

      def close_version!
        VersionService.close(druid:,
                             version: repository_object.head_version.version,
                             accession_args: { lane_id: 'low', context: }, # Always send to low queue.
                             description: nil) # Use the existing version description
      end

      def context
        migrator_class.workflow_context || {}
      end

      # @return [Hash] the model hash for the last closed version with an incremented version number
      def build_incremented_last_closed_version_model_hash
        new_version = repository_object.last_closed_version.version + 1
        to_model_hash(repository_object.last_closed_version, version: new_version).freeze
      end

      def adjust_versions(new_version)
        @last_closed_version = head_version
        @opened_version = new_version
        @head_version = new_version
      end

      def add_migration_tag!
        return unless migrator_class.migration_tag

        AdministrativeTags.create(identifier: druid, tags: [migrator_class.migration_tag])
      end
    end

    # Runner that migrates a RepositoryObject by committing the migrated model hashes to the database.
    # Note that this migrates all versions (though it is up to the migrator to decide which actually to change.)
    class CommitRunner < BaseRunner
      # @return [Array<Result>] results for the migration attempt
      def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        original_model_hash_map = build_original_model_hash_map.tap do |original_model_hash_map|
          # Modify as if the version was open if the version is going to be opened.
          # This allows for migration errors to occur before actually opening the version.
          if migrator_class.version? && repository_object.closed?
            model_hash = build_incremented_last_closed_version_model_hash
            original_model_hash_map[model_hash['version']] = model_hash
            adjust_versions(model_hash['version'])
          end
        end
        # Keep track of which model hashes are valid.
        original_model_hash_valid_map = build_original_model_hash_valid_map(original_model_hash_map:)

        # Do the migration on the model hashes.
        migrated_model_hashes = original_model_hash_map.values.filter_map do |model_hash|
          migrated_model_hash = migrate_model_hash(model_hash:,
                                                   valid: original_model_hash_valid_map[model_hash['version']])
          next if migrated_model_hash == model_hash # Don't add if nothing changed

          migrated_model_hash
        rescue StandardError => e
          Rails.logger.info("#{druid} (version #{model_hash['version']}) failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}") # rubocop:disable Layout/LineLength
          return [Result.new(status: 'ERROR', version: model_hash['version'], exception: e.message,
                             **result_id_attrs)]
        end

        return [Result.new(status: 'UNCHANGED', **result_id_attrs)] if migrated_model_hashes.empty?

        invalid_results = validate_migrated_model_hashes(migrated_model_hashes:, original_model_hash_valid_map:)
        return invalid_results if invalid_results.present?

        # Note that open_version! is dryrun-aware.
        open_version! if migrator_class.version? && !open_before_migration?

        unless dryrun?
          commit!(migrated_model_hashes:)

          Publish::MetadataTransferService.publish(druid:) if migrator_class.publish?
          # Not closing objects that were already open.
          close_version! if migrator_class.version? && !open_before_migration?
          add_migration_tag!
        end

        Rails.logger.info("#{druid} successfully migrated#{' (dry run)' if dryrun?}")

        migrated_model_hashes.map do |migrated_model_hash|
          Result.new(status: "MIGRATED#{' (dry run)' if dryrun?}", version: migrated_model_hash['version'],
                     **result_id_attrs)
        end
      rescue StandardError => e
        Rails.logger.info("#{druid} failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}")
        [Result.new(status: 'ERROR', exception: e.message, **result_id_attrs)]
      end

      private

      def build_original_model_hash_map
        repository_object.versions
                         .select(&:has_cocina?)
                         .to_h do |repository_object_version|
                           [repository_object_version.version,
                            to_model_hash(repository_object_version)]
                         end
      end

      # @return [Hash{Integer => Boolean}] a map of version number to whether the model hash is valid
      def build_original_model_hash_valid_map(original_model_hash_map:)
        original_model_hash_map.transform_values do |model_hash|
          valid_model_hash?(model_hash)
        end
      end

      def valid_model_hash?(model_hash)
        Cocina::Models.build(model_hash)
        true
      rescue Cocina::Models::ValidationError, Dry::Struct::Error
        false
      end

      # @return [Array(Array<Result>] invalid results
      def validate_migrated_model_hashes(migrated_model_hashes:, original_model_hash_valid_map:)
        migrated_model_hashes.filter_map do |migrated_model_hash|
          if migrator_class.allow_invalid?
            next unless [opened_version, last_closed_version].include?(migrated_model_hash['version'])
          else
            next unless original_model_hash_valid_map[migrated_model_hash['version']]
          end

          Cocina::Models.build(migrated_model_hash)

          nil
        rescue Cocina::Models::ValidationError, Dry::Struct::Error => e
          Result.new(status: 'INVALID', exception: e.message, version: migrated_model_hash['version'],
                     **result_id_attrs)
        end
      end

      def commit!(migrated_model_hashes:)
        repository_object.transaction do
          repository_object.reload # ensure we have the latest versions before updating
          migrated_model_hashes.each do |migrated_model_hash|
            repository_object_version = repository_object.versions.find do |repository_object_version|
              repository_object_version.version == migrated_model_hash['version']
            end
            repository_object_version.update!(migrated_model_hash_for_update(migrated_model_hash))
          end
        end
      end

      def migrated_model_hash_for_update(migrated_model_hash)
        migrated_model_hash
          .except('externalIdentifier', 'version', 'cocinaVersion')
          .tap do |object_hash|
            object_hash['cocina_version'] = Cocina::Models::VERSION # When saving, set to latest cocina version.
            object_hash['content_type'] = object_hash.delete('type')
          end
      end
    end

    # A runner that migrates a RepositoryObject by using UpdateObjectService to persist the migrated model hashes.
    # Note that this only migrates the head version, not all versions.
    class CocinaUpdateRunner < BaseRunner
      def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if repository_object.open?
          original_cocina_model_hash = to_model_hash(repository_object.opened_version)
        else
          # Modify as if the version was open if the version is going to be opened.
          # This allows for migration errors to occur before actually opening the version.

          original_cocina_model_hash = build_incremented_last_closed_version_model_hash
          adjust_versions(original_cocina_model_hash['version'])
        end

        begin
          migrated_model_hash = migrate_model_hash(model_hash: original_cocina_model_hash, valid: true)
        rescue StandardError => e
          Rails.logger.info("#{druid} (version #{original_cocina_model_hash['version']}) failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}") # rubocop:disable Layout/LineLength
          return [Result.new(status: 'ERROR', version: original_cocina_model_hash['version'], exception: e.message,
                             **result_id_attrs)]
        end

        return [Result.new(status: 'UNCHANGED', **result_id_attrs)] if migrated_model_hash == original_cocina_model_hash

        begin
          migrated_cocina_object = Cocina::Models.build(migrated_model_hash)
        rescue Cocina::Models::ValidationError, Dry::Struct::Error => e
          return [Result.new(status: 'INVALID', exception: e.message, version: migrated_model_hash['version'],
                             **result_id_attrs)]
        end

        open_version! unless open_before_migration?

        unless dryrun?
          cocina_update!(migrated_cocina_object:)
          close_version! unless open_before_migration? # Not closing objects that were already open.
          add_migration_tag!
        end

        Rails.logger.info("#{druid} successfully migrated#{' (dry run)' if dryrun?}")

        [Result.new(status: "MIGRATED#{' (dry run)' if dryrun?}", version: migrated_model_hash['version'],
                    **result_id_attrs)]
      rescue StandardError => e
        Rails.logger.info("#{druid} failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}")
        [Result.new(status: 'ERROR', exception: e.message, **result_id_attrs)]
      end

      private

      def cocina_update!(migrated_cocina_object:)
        migrated_cocina_object_with_metadata = Cocina::Models.with_metadata(migrated_cocina_object,
                                                                            repository_object.external_lock)
        UpdateObjectService.update(cocina_object: migrated_cocina_object_with_metadata,
                                   skip_open_check: true)
      end
    end
  end
end
