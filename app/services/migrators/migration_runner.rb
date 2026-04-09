# frozen_string_literal: true

module Migrators
  # Performs migration on a RepositoryObject given a migrator class.
  class MigrationRunner # rubocop:disable Metrics/ClassLength
    # see README for explanation of modes
    MODES = %i[dryrun migrate].freeze
    DEFAULT_MODE = :dryrun

    Result = Struct.new(:id, :external_identifier, 'version', :status, :exception)

    # @return [Array<Result>] results for the migration attempts
    def self.migrate_druid_list(migrator_class:, mode:, druids_slice:)
      druids_slice.each_slice(50).flat_map do |druids_slice_batch|
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

      raise ArgumentError("invalid mode #{mode}") unless MODES.include?(mode)
    end

    # @return [Array<Result>] results for the migration attempt
    def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      original_model_hash_map = build_original_model_hash_map.tap do |original_model_hash_map|
        # Modify as if the version was open if the version is going to be opened.
        # This allows for migration errors to occur before actually opening the version.
        if migrator_class.version? && repository_object.closed?
          new_version = repository_object.last_closed_version.version + 1
          model_hash = to_model_hash(repository_object.last_closed_version, version: new_version)
          original_model_hash_map[new_version] = model_hash.freeze
          @last_closed_version = head_version
          @opened_version = new_version
          @head_version = new_version
        end
      end

      # Do the migration on the model hashes.
      migrated_model_hashes = original_model_hash_map.values.filter_map do |model_hash|
        migrated_model_hash = migrate_model_hash(model_hash:)
        next if migrated_model_hash == model_hash # Don't add if nothing changed

        migrated_model_hash
      rescue StandardError => e
        Rails.logger.info("#{druid} (version #{model_hash['version']}) failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}") # rubocop:disable Layout/LineLength
        return [Result.new(status: 'ERROR', version: model_hash['version'], exception: e.message, **result_id_attrs)]
      end

      return [Result.new(status: 'UNCHANGED', **result_id_attrs)] if migrated_model_hashes.empty?

      invalid_results = validate_migrated_model_hashes(migrated_model_hashes:, original_model_hash_map:)
      return invalid_results if invalid_results.present?

      open_version! if migrator_class.version? # Note that open_version! is dryrun-aware.

      unless dryrun?
        if migrator_class.cocina_update?
          cocina_update!(migrated_model_hashes:)
        else
          commit!(migrated_model_hashes:)
        end

        Publish::MetadataTransferService.publish(druid:) if migrator_class.publish?
        close_version! if migrator_class.version?
      end

      Rails.logger.info("#{druid} successfully migrated#{' (dry run)' if dryrun?}")

      migrated_model_hashes.map do |migrated_model_hash|
        Result.new(status: 'MIGRATED', version: migrated_model_hash['version'], **result_id_attrs)
      end
    rescue StandardError => e
      Rails.logger.info("#{druid} failed to migrate#{' (dry run)' if dryrun?}: #{e.message} -- #{e.backtrace}")
      [Result.new(status: 'ERROR', exception: e.message, **result_id_attrs)]
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

    def build_original_model_hash_map
      if migrator_class.cocina_update?
        repository_object.open? ? { opened_version => to_model_hash(repository_object.opened_version) } : {}
      else
        repository_object.versions
                         .select(&:has_cocina?)
                         .to_h do |repository_object_version|
                           [repository_object_version.version,
                            to_model_hash(repository_object_version)]
                         end
      end
    end

    def open_version!
      cocina_object = repository_object.head_version.to_cocina
      version_service = VersionService.new(druid: cocina_object.externalIdentifier, version: cocina_object.version,
                                           repository_object:)
      return if version_service.open?

      # This allows us to know if the object can be opened for versioning without actually opening it during a dry run
      if dryrun?
        # Raise an error if the migration is trying to version an object that is not openable
        version_service.ensure_openable!(assume_accessioned: false)
        return
      end

      version_service.open(cocina_object:, description: migrator_class.version_description, assume_accessioned: false)
    end

    def result_id_attrs
      { id: repository_object.id, external_identifier: repository_object.external_identifier }
    end

    def valid_model_hash?(model_hash)
      Cocina::Models.build(model_hash)
      true
    rescue Cocina::Models::ValidationError, Dry::Struct::Error
      false
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

    def migrate_model_hash(model_hash:)
      migrator_class.new(model_hash: model_hash.deep_dup,
                         opened_version: model_hash['version'] == opened_version,
                         last_closed_version: model_hash['version'] == last_closed_version,
                         head_version: model_hash['version'] == head_version,
                         valid: valid_model_hash?(model_hash)).migrate
    end

    # @return [Array<Result>] results for the migration attempts of the migrated model hashes.
    def validate_migrated_model_hashes(migrated_model_hashes:, original_model_hash_map:)
      migrated_model_hashes.filter_map do |migrated_model_hash|
        if migrator_class.allow_invalid?
          next unless [opened_version, last_closed_version].include?(migrated_model_hash['version'])
        else
          next unless valid_model_hash?(original_model_hash_map[migrated_model_hash['version']])
        end

        Cocina::Models.build(migrated_model_hash)
        nil
      rescue Cocina::Models::ValidationError, Dry::Struct::Error => e
        Result.new(status: 'INVALID', exception: e.message, version: migrated_model_hash['version'], **result_id_attrs)
      end
    end

    def cocina_update!(migrated_model_hashes:)
      migrated_cocina_object = Cocina::Models.build(migrated_model_hashes.first)
      migrated_cocina_object_with_metadata = Cocina::Models.with_metadata(migrated_cocina_object,
                                                                          repository_object.external_lock)
      UpdateObjectService.update(cocina_object: migrated_cocina_object_with_metadata,
                                 skip_open_check: true)
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

    def close_version!
      VersionService.close(druid:,
                           version: repository_object.head_version.version,
                           description: nil) # Use the existing version description
    end
  end
end
