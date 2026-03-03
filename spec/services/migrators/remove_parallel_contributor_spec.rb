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
      { 'title' => 'Test Title', 'contributor' => contributor, 'relatedResource' => related_resource, 'event' => event,
        'purl' => 'https://purl.stanford.edu' }
    end
    let(:contributor) { [{ 'name' => 'Test Contributor', 'parallelContributor' => [] }] }
    let(:related_resource) do
      [{ 'title' => 'Test Title', 'contributor' => contributor },
       { 'title' => 'Test Title 2', 'contributor' => contributor,
         'relatedResource' => [{ 'title' => 'Nested Test Title', 'contributor' => contributor }] }]
    end
    let(:event) { [{ 'name' => 'Test Event', 'contributor' => contributor }] }
    let(:repository_object_version) do
      build(:repository_object_version, label: 'Test DRO', description:)
    end
    let(:repository_object) { create(:repository_object, :with_repository_object_version, repository_object_version:) }

    it 'removes parallelContributor from contributors, events, and relatedResources' do
      migrator.migrate
      expect(repository_object.versions.last.description['contributor']).to eq([{ 'name' => 'Test Contributor' }])
      expect(repository_object.versions.last.description['event']).to eq([{ 'name' => 'Test Event',
                                                                            'contributor' => [{
                                                                              'name' => 'Test Contributor'
                                                                            }] }])
      expect(repository_object.versions.last.description['relatedResource']).to eq([{ 'title' => 'Test Title',
                                                                                      'contributor' => [{
                                                                                        'name' => 'Test Contributor'
                                                                                      }] },
                                                                                    { 'title' => 'Test Title 2',
                                                                                      'contributor' => [{
                                                                                        'name' => 'Test Contributor'
                                                                                      }],
                                                                                      'relatedResource' => [{
                                                                                        'title' => 'Nested Test Title',
                                                                                        'contributor' => [{
                                                                                          'name' => 'Test Contributor'
                                                                                        }]
                                                                                      }] }])
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
