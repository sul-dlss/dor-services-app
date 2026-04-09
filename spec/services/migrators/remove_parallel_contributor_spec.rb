# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveParallelContributor do
  subject(:migrator) { described_class.new(model_hash: model_hash, valid: true, opened_version: false, last_closed_version: false, head_version: false) }

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
        'event' => event,
        'adminMetadata' => admin_metadata,
        'purl' => 'https://purl.stanford.edu' }
    end
    let(:contributor) { [{ 'name' => 'Test Contributor', 'parallelContributor' => [] }] }
    let(:related_resource) do
      [{ 'title' => 'Test Title', 'contributor' => contributor }]
    end
    let(:event) do
      [{ 'name' => 'Test Event', 'contributor' => contributor, 'parallelEvent' => [{ 'contributor' => contributor }] }]
    end
    let(:admin_metadata) do
      { 'name' => 'Test Event', 'contributor' => contributor,
        'event' => [{ 'name' => 'Test Admin Event', 'contributor' => contributor, 'parallelEvent' => [{ 'contributor' => contributor }] }] }
    end

    it 'removes parallelContributor from contributors in events, relatedResources, adminMetadata' do
      migrated_description = migrated_model_hash['description']
      expect(migrated_description['contributor']).to eq([{ 'name' => 'Test Contributor' }])
      expect(migrated_description['event']).to eq([{ 'name' => 'Test Event',
                                                     'contributor' => [{
                                                       'name' => 'Test Contributor'
                                                     }],
                                                     'parallelEvent' => [{ 'contributor' => [{
                                                       'name' => 'Test Contributor'
                                                     }] }] }])
      expect(migrated_description['relatedResource']).to eq([{ 'title' => 'Test Title',
                                                               'contributor' => [{
                                                                 'name' => 'Test Contributor'
                                                               }] }])
      expect(migrated_description['adminMetadata']).to eq({ 'name' => 'Test Event',
                                                            'contributor' => [{
                                                              'name' => 'Test Contributor'
                                                            }],
                                                            'event' => [{ 'name' => 'Test Admin Event',
                                                                          'contributor' => [{
                                                                            'name' => 'Test Contributor'
                                                                          }],
                                                                          'parallelEvent' => [
                                                                            {
                                                                              'contributor' => [
                                                                                {
                                                                                  'name' => 'Test Contributor'
                                                                                }
                                                                              ]
                                                                            }
                                                                          ] }] })
    end
  end

  describe '#migration_strategy' do
    it 'returns commit since using base default' do
      expect(described_class.migration_strategy).to eq :commit
    end
  end
end
