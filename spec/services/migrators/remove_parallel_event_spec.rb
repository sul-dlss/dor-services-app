# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveParallelEvent do
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
        'relatedResource' => related_resource,
        'event' => event,
        'adminMetadata' => admin_metadata,
        'purl' => 'https://purl.stanford.edu' }
    end
    let(:related_resource) do
      [{ 'title' => 'Test Related Resource Title', 'event' => event, 'adminMetadata' => admin_metadata }]
    end
    let(:event) do
      [
        { 'location' => location, 'parallelEvent' => [{ 'name' => 'Test Parallel Event' }] },
        { 'displayLabel' => 'Event with parallel event', 'parallelEvent' => [{ 'name' => 'Test Parallel Event' }] }
      ]
    end
    let(:location) { [{ 'value' => 'Test Location' }] }
    let(:admin_metadata) do
      { 'name' => 'Test Admin Metadata',
        'event' => [{ 'location' => location, 'parallelEvent' => [{ 'name' => 'Test Admin Parallel Event' }] }] }
    end

    it 'removes parallelEvent from events in events, relatedResources, adminMetadata' do
      migrated_description = migrated_model_hash['description'].with_indifferent_access
      expect(migrated_description)
        .to match(
          {
            title: 'Test Title',
            relatedResource: [
              {
                title: 'Test Related Resource Title',
                event: [{ location: [{ value: 'Test Location' }] }],
                adminMetadata: {
                  name: 'Test Admin Metadata',
                  event: [{ location: [{ value: 'Test Location' }] }]
                }
              }
            ],
            event: [{ location: [{ value: 'Test Location' }] }],
            adminMetadata: {
              name: 'Test Admin Metadata',
              event: [{ location: [{ value: 'Test Location' }] }]
            },
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
