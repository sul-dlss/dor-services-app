# frozen_string_literal: true

module Cocina
  # Generates identifiers for use within Cocina model.
  class IdGenerator
    ID_NAMESPACE = 'http://cocina.sul.stanford.edu'

    def self.generate_or_existing_fileset_id(druid:, resource_id: nil)
      bare_druid = druid.delete_prefix('druid:')
      return resource_id if resource_id.present? && resource_id.starts_with?("#{ID_NAMESPACE}/fileSet/#{bare_druid}")

      resource_id = if resource_id.nil?
                      SecureRandom.uuid
                    elsif resource_id.starts_with?("#{ID_NAMESPACE}/fileSet/")
                      resource_id.split('/').last
                    else
                      resource_id
                    end

      [
        ID_NAMESPACE,
        'fileSet',
        bare_druid,
        resource_id
      ].join('/')
    end

    def self.generate_or_existing_file_id(druid:, file_id: nil, resource_id: nil)
      bare_druid = druid.delete_prefix('druid:')
      return file_id if file_id.present? && file_id.starts_with?("#{ID_NAMESPACE}/file/#{bare_druid}")

      resource_id = if resource_id.nil?
                      SecureRandom.uuid
                    elsif resource_id.starts_with?("#{ID_NAMESPACE}/fileSet/")
                      resource_id.split('/').last
                    else
                      resource_id
                    end

      [
        ID_NAMESPACE,
        'file',
        bare_druid,
        resource_id,
        file_id.presence || SecureRandom.uuid
      ].join('/')
    end
  end
end
