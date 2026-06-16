# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveNestedIdentifier do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version: false, last_closed_version: false,
                        head_version: false)
  end

  describe 'migrate' do
    subject(:migrated_model_hash) { migrator.migrate }

    let(:model_hash) do
      # Only providing description instead of complete model hash.
      { 'description' => description }
    end

    let(:description) do
      { 'title' => 'Test Title',
        'contributor' => contributor,
        'relatedResource' => related_resource,
        # 'event' => event,
        # 'adminMetadata' => admin_metadata,
        'identifier' => identifier,
        'purl' => 'https://purl.stanford.edu' }
    end

    let(:identifier) do
      [{ 'type' => 'local',
         'value' => 'sul-chs:PC010_09_1009',
         'identifier' => [],
         'displayLabel' => 'Source ID' }]
    end
    let(:contributor) { [{ 'name' => 'Test Contributor', 'identifier' => identifier }] }
    let(:related_resource) do
      [{ 'title' => 'Test Related Resource Title', 'identifier' => identifier }]
    end

    it 'removes nested identifier from description' do
      migrated_description = migrated_model_hash['description'].with_indifferent_access
      expect(migrated_description)
        .to match(
          {
            title: 'Test Title',
            contributor: [{ name: 'Test Contributor',
                            identifier: [{ type: 'local', value: 'sul-chs:PC010_09_1009',
                                           displayLabel: 'Source ID' }] }],
            relatedResource: [
              {
                title: 'Test Related Resource Title',
                identifier: [{ type: 'local', value: 'sul-chs:PC010_09_1009', displayLabel: 'Source ID' }]
              }
            ],
            identifier: [{ type: 'local', value: 'sul-chs:PC010_09_1009', displayLabel: 'Source ID' }],
            purl: 'https://purl.stanford.edu'
          }
        )
    end
  end

  describe '#migration_strategy' do
    it 'returns commit since using base default' do
      expect(described_class.migration_strategy).to eq :commit
    end
  end
end
