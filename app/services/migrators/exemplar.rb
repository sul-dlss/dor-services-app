# frozen_string_literal: true

module Migrators
  # Very basic migrator that will be used to test the cocina migration runner and illustrate usage.
  # See parent class and Migrators::MigrationRunner for more information.
  class Exemplar < Base
    # NOTE: these are QA druids from 2026-03-30
    TEST_DRUIDS = [
      'druid:bb029tv6105',
      'druid:bb086gc7372'
    ].freeze

    def migrate # rubocop:disable Metrics/AbcSize
      return model_hash unless TEST_DRUIDS.include?(model_hash['externalIdentifier'])

      model_hash['label'] = mark_migrated(model_hash['label'])
      title = model_hash.dig('description', 'title', 0, 'value')
      model_hash['description']['title'].first['value'] = mark_migrated(title) if title.present?
      model_hash
    end

    private

    def mark_migrated(label)
      "#{label.gsub(/ - migrated .+$/, '')} - migrated #{Time.now.utc.iso8601}"
    end
  end
end
