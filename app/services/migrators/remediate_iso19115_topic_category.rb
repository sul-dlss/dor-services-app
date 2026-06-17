# frozen_string_literal: true

module Migrators
  # Moves ISO 19115 Topic Category coded values from subject.uri to subject.code.
  # These terms were incorrectly stored as URIs due to MODS limitations.
  # Only subjects with source.code == "ISO19115TopicCategory" are affected.
  # See parent class and Migrators::MigrationRunner for more information.
  class RemediateIso19115TopicCategory < Base
    def self.migration_strategy
      :cocina_update
    end

    def self.version_description
      'Remediate ISO 19115 Topic Category subjects: move coded value from uri to code field.'
    end

    def migrate
      remediate_subjects_in_resource(model_hash['description'])
      model_hash
    end

    private

    def remediate_subjects_in_resource(resource_hash)
      return if resource_hash.nil?

      Array(resource_hash['subject']).each do |subject|
        next unless subject.dig('source', 'code') == 'ISO19115TopicCategory'
        next unless subject.key?('uri')
        next if subject.key?('code')

        subject['code'] = subject.delete('uri')
      end

      Array(resource_hash['relatedResource']).each do |related_resource_hash|
        remediate_subjects_in_resource(related_resource_hash)
      end
    end
  end
end
