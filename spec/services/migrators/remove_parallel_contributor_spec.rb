# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveParallelContributor do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object) { create(:repository_object, :with_repository_object_version) }

  describe '#migrate?' do
    it 'returns true' do
      expect(migrator.migrate?).to be true
    end
  end

  describe 'migrate' do
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
    let(:repository_object_version) do
      build(:repository_object_version, label: 'Test DRO', description:)
    end
    let(:repository_object) { create(:repository_object, :with_repository_object_version, repository_object_version:) }

    it 'removes parallelContributor from contributors in events, relatedResources, adminMetadata' do
      migrator.migrate
      expect(repository_object.versions.last.description['contributor']).to eq([{ 'name' => 'Test Contributor' }])
      expect(repository_object.versions.last.description['event']).to eq([{ 'name' => 'Test Event',
                                                                            'contributor' => [{
                                                                              'name' => 'Test Contributor'
                                                                            }],
                                                                            'parallelEvent' => [{ 'contributor' => [{
                                                                              'name' => 'Test Contributor'
                                                                            }] }] }])
      expect(repository_object.versions.last.description['relatedResource']).to eq([{ 'title' => 'Test Title',
                                                                                      'contributor' => [{
                                                                                        'name' => 'Test Contributor'
                                                                                      }] }])
      expect(repository_object.versions.last.description['adminMetadata']).to eq({ 'name' => 'Test Event',
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

  describe '#publish?' do
    it 'returns false since using base default' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false since using base default' do
      expect(migrator.version?).to be false
    end
  end
end
