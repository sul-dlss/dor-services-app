# frozen_string_literal: true

module Cocina
  # Generates identifiers for use within Cocina model.
  class IdGenerator
    def self.generate_or_existing_fileset_id(druid:, resource_id: nil)
      new(druid:, resource_id:).generate_or_existing_fileset_id
    end

    def self.generate_or_existing_file_id(druid:, file_id: nil, resource_id: nil)
      new(druid:, resource_id:, file_id:).generate_or_existing_file_id
    end

    ID_NAMESPACE = 'https://cocina.sul.stanford.edu'

    def initialize(druid:, file_id: nil, resource_id: nil)
      @druid = druid.delete_prefix('druid:')
      @file_id, @resource_id = derive_file_and_resource_ids_from(file_id).presence
      @file_id ||= SecureRandom.uuid
      @resource_id ||= derive_resource_id_from(resource_id).presence || SecureRandom.uuid
    end

    def generate_or_existing_fileset_id
      "#{ID_NAMESPACE}/fileSet/#{druid}-#{resource_id}"
    end

    def generate_or_existing_file_id
      "#{ID_NAMESPACE}/file/#{druid}-#{resource_id}/#{file_id}"
    end

    private

    attr_reader :druid, :file_id, :resource_id

    def derive_file_and_resource_ids_from(file_id)
      return if file_id.blank?

      *, derived_resource_id, derived_file_id = file_id.split('/') if file_id&.starts_with?("#{ID_NAMESPACE}/file/")

      [derived_file_id || file_id, derived_resource_id]
    end

    def derive_resource_id_from(resource_id)
      return if resource_id.blank?

      if resource_id&.starts_with?("#{ID_NAMESPACE}/fileSet/")
        derived_resource_id = resource_id
                              .split('/')
                              .last
                              .split('-')
                              .reject { |segment| DruidTools::Druid.valid?(segment) }
                              .join('-')
      end

      derived_resource_id || resource_id
    end
  end
end
