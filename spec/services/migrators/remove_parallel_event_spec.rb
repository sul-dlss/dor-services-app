# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveParallelEvent do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version:, last_closed_version:,
                        head_version: false)
  end

  let(:opened_version) { false }
  let(:last_closed_version) { false }

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
    let(:location) { [{ 'value' => 'Test Location' }] }

    let(:description_hash_without_parallel_event) do
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
    end

    context 'when parallelEvent is empty' do
      let(:event) do
        [
          { 'location' => location, 'parallelEvent' => [] },
          { 'displayLabel' => 'Event with parallel event', 'parallelEvent' => [] }
        ]
      end

      let(:admin_metadata) do
        { 'name' => 'Test Admin Metadata',
          'event' => [{ 'location' => location, 'parallelEvent' => [] }] }
      end

      it 'removes parallelEvent from events in events, relatedResources, adminMetadata' do
        migrated_description = migrated_model_hash['description'].with_indifferent_access
        expect(migrated_description).to match(description_hash_without_parallel_event)
      end
    end

    context 'when parallelEvent is missing' do
      let(:event) do
        [
          { 'location' => location },
          { 'displayLabel' => 'Event with parallel event' }
        ]
      end

      let(:admin_metadata) do
        { 'name' => 'Test Admin Metadata',
          'event' => [{ 'location' => location }] }
      end

      it 'leaves unchanged' do
        migrated_description = migrated_model_hash['description'].with_indifferent_access
        expect(migrated_description)
          .to match(description)
      end
    end

    context 'when parallelEvent is populated' do
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

      context 'when opened version' do
        let(:opened_version) { true }

        it 'removes parallelEvent from events in events, relatedResources, adminMetadata' do
          migrated_description = migrated_model_hash['description'].with_indifferent_access
          expect(migrated_description).to match(description_hash_without_parallel_event)
        end
      end

      context 'when last closed version' do
        let(:last_closed_version) { true }

        it 'removes parallelEvent from events in events, relatedResources, adminMetadata' do
          migrated_description = migrated_model_hash['description'].with_indifferent_access
          expect(migrated_description).to match(description_hash_without_parallel_event)
        end
      end

      it 'leaves unchanged' do
        migrated_description = migrated_model_hash['description'].with_indifferent_access
        expect(migrated_description)
          .to match(description)
      end
    end
  end

  describe '#migration_strategy' do
    it 'returns commit since using base default' do
      expect(described_class.migration_strategy).to eq :commit
    end
  end
end
