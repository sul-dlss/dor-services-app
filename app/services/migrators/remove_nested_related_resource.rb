# frozen_string_literal: true

module Migrators
  # Removes a nested related resource property from description in all objects and versions.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveNestedRelatedResource < Base
    def migrate
      Array(model_hash.dig('description', 'relatedResource')).each do |related_resource_hash|
        nested_related_resource = related_resource_hash['relatedResource'].present?

        # If the nested relatedResource is empty, delete the property.
        next related_resource_hash.delete('relatedResource') unless nested_related_resource

        # If not empty, but this is an old version, leave it.
        next unless opened_version? || last_closed_version?

        # If not empty, but a open or last closed version, raise an error.
        # These should have been mediated.
        raise 'Nested relatedResource found' if opened_version? || last_closed_version?
      end
      model_hash
    end
  end
end
