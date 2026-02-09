# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryObject do
  subject(:repository_object) { build(:repository_object, **attrs) }

  let(:attrs) do
    {
      external_identifier: 'druid:bc868mh7756',
      object_type: 'dro',
      source_id: 'sul:dlss:testing'
    }
  end

  describe 'validation' do
    it { is_expected.to be_valid }

    context 'without external_identifier' do
      let(:attrs) { { external_identifier: nil } }

      it { is_expected.not_to be_valid }
    end

    context 'without object_type' do
      let(:attrs) { { object_type: nil } }

      it { is_expected.not_to be_valid }
    end

    context 'with duplicate external_identifier' do
      let(:attrs) { { external_identifier: existing_druid } }
      let(:existing_druid) { create(:repository_object).external_identifier }

      it 'raises an error' do
        expect { repository_object.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'with duplicate source_id' do
      let(:attrs) { { source_id: existing_source_id } }
      let(:existing_source_id) { create(:repository_object).source_id }

      it 'raises an error' do
        expect { repository_object.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'with a collection (where source_id is optional)' do
      let(:attrs) { { source_id: nil, object_type: 'collection' } }

      it { is_expected.to be_valid }
    end

    context 'with a dro (where source_id is mandatory)' do
      let(:attrs) { { source_id: nil } }

      it { is_expected.not_to be_valid }
    end

    context 'when last closed and opened point at same version' do
      before do
        repository_object.save # we need at least one persisted version so we can run this validation
        repository_object.opened_version = repository_object.last_closed_version = repository_object.versions.first
      end

      it { is_expected.not_to be_valid }
    end

    # NOTE: I'm not sure this can currently happen?
    context 'when current points at something other than last closed or opened' do
      before do
        repository_object.save # we need at least one persisted version so we can run this validation
        repository_object.update(head_version: repository_object.versions.first)
        repository_object.update(last_closed_version: repository_object.versions.create!(version: 2,
                                                                                         version_description: 'closed'))
        repository_object.update(opened_version: repository_object.versions.create!(version: 3,
                                                                                    version_description: 'draft'))
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe 'automatic first version creation' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    it 'has a single version' do
      expect(repository_object.versions.count).to eq(1)
    end

    it 'has a version with the expected attributes' do
      expect(repository_object.versions.first.version).to eq(1)
      expect(repository_object.versions.first.version_description).to eq('Initial version')
    end
  end

  describe 'destruction' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    before do
      repository_object.update(head_version: repository_object.versions.first)
    end

    it 'does not raise on destroy' do
      expect { repository_object.destroy }.not_to raise_error
    end
  end

  describe '.members_of_collection' do
    let(:druid) { 'druid:xz456jk0987' }
    let(:opened_version) { create(:repository_object).opened_version }

    it 'returns an empty list' do
      expect(described_class.currently_members_of_collection(druid)).to eq([])
    end

    context 'when object version has a relevant member order' do
      let(:attrs) do
        {
          structural: {
            isMemberOf: druid
          }
        }
      end

      before do
        opened_version.update(attrs)
      end

      it 'returns the expected object version' do
        expect(described_class.currently_members_of_collection(druid)).to eq([opened_version.repository_object])
      end
    end
  end

  describe '#publishable?' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    context 'without a last closed version' do
      it 'returns false' do
        expect(repository_object).not_to be_publishable
      end
    end

    context 'with a last closed version lacking cocina' do
      before do
        repository_object.update(last_closed_version: repository_object.versions
                                                      .create!(version: 2, version_description: 'closed'))
      end

      it 'returns false' do
        expect(repository_object).not_to be_publishable
      end
    end

    context 'with a last closed version containing cocina' do
      before do
        repository_object
          .update(last_closed_version: repository_object.versions
                                       .create!(version: 2, version_description: 'closed', cocina_version: 1))
      end

      it 'returns true' do
        expect(repository_object).to be_publishable
      end
    end
  end

  describe '#open_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    let(:description) { 'my new version' }

    it 'raises when version is already open' do
      expect { repository_object.open_version!(description:) }.to raise_error(described_class::VersionAlreadyOpened)
    end

    context 'when closed' do
      before do
        repository_object.close_version!
      end

      it 'creates a new version and updates the head and opened version pointers' do
        expect { repository_object.open_version!(description:) }.to change(RepositoryObjectVersion, :count).by(1)
        newly_created_version = repository_object.versions.last
        expect(newly_created_version.version).to eq(2)
        expect(repository_object.head_version).to eq(newly_created_version)
        expect(repository_object.opened_version).to eq(newly_created_version)
        expect(newly_created_version.version_description).to eq(description)
        expect(newly_created_version.closed_at).to be_nil
      end
    end

    context 'when based on an earlier version' do
      before do
        repository_object.head_version.label = 'Version 1'
        repository_object.close_version!
        repository_object.open_version!(description: 'Another version')
        repository_object.head_version.label = 'Version 2'
        repository_object.close_version!
      end

      it 'creates a new version and updates the head and opened version pointers' do
        expect do
          repository_object.open_version!(description:,
                                          from_version: repository_object.versions.first)
        end.to change(RepositoryObjectVersion, :count).by(1)
        newly_created_version = repository_object.versions.last
        expect(newly_created_version.version).to eq(3)
        expect(repository_object.head_version).to eq(newly_created_version)
        expect(repository_object.opened_version).to eq(newly_created_version)
        expect(newly_created_version.label).to eq 'Version 1'
        expect(newly_created_version.closed_at).to be_nil
      end
    end
  end

  describe '#close_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    let(:description) { 'my closed version' }

    it 'sets the closed_at field' do
      expect do
        repository_object.close_version!
      end.to change(repository_object.head_version,
                    :closed_at).to(instance_of(ActiveSupport::TimeWithZone))
    end

    it 'updates the head, last closed, and opened version pointers' do
      repository_object.close_version!
      closed_version = repository_object.versions.find_by(version: 1)
      expect(repository_object.head_version).to eq(closed_version)
      expect(repository_object.last_closed_version).to eq(closed_version)
      expect(repository_object.opened_version).to be_nil
    end

    it 'updates the version description' do
      repository_object.close_version!(description:)
      expect(repository_object.head_version.version_description).to eq(description)
    end

    context 'when closed' do
      before do
        repository_object.close_version!
      end

      it 'raises when version is already closed' do
        expect { repository_object.close_version! }.to raise_error(described_class::VersionNotOpened)
      end
    end
  end

  describe '#update_opened_version_from' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    let(:cocina_object) { build(:dro) }

    it 'updates the opened version using a object type-specific Cocina hash' do
      expect { repository_object.update_opened_version_from(cocina_object:) }
        .to change(repository_object.opened_version, :cocina_version).from(nil).to(Cocina::Models::VERSION)
        .and change(repository_object.opened_version, :content_type).from(nil).to(Cocina::Models::ObjectType.object)
        .and change(repository_object.opened_version, :label).from(nil).to('factory DRO label')
        .and change(repository_object.opened_version, :access).from(nil).to(instance_of(Hash))
        .and change(repository_object.opened_version, :administrative).from(nil).to(instance_of(Hash))
        .and change(repository_object.opened_version, :description).from(nil).to(instance_of(Hash))
        .and change(repository_object.opened_version, :identification).from(nil).to(instance_of(Hash))
        .and change(repository_object.opened_version, :structural).from(nil).to(instance_of(Hash))
    end
  end

  describe '#version_xml' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    let(:druid) { attrs[:external_identifier] }
    let(:expected_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
          <versionMetadata objectId="#{druid}">
            <version versionId="1">
              <description>
                Initial version
              </description>
            </version>
            <version versionId="2">
              <description>
                Version 2.0.0
              </description>
            </version>
          </versionMetadata>
      XML
    end

    before do
      create(:repository_object_version, version: 2, repository_object:, version_description: 'Version 2.0.0')
    end

    it 'returns xml' do
      expect(repository_object.version_xml).to be_equivalent_to(expected_xml)
    end
  end

  describe '#can_discard_open_version?' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    context 'when head version is open' do
      before do
        repository_object.close_version!
        repository_object.head_version.update!(cocina_version: Cocina::Models::VERSION)
        repository_object.open_version!(description: 'draft')
      end

      it 'returns true' do
        expect(repository_object.can_discard_open_version?).to be(true)
      end
    end

    context 'when head version is closed' do
      before do
        repository_object.close_version!
        repository_object.head_version.update!(cocina_version: Cocina::Models::VERSION)
        repository_object.open_version!(description: 'draft')
        repository_object.close_version!
      end

      it 'returns false' do
        expect(repository_object.can_discard_open_version?).to be(false)
      end
    end

    context 'when head version is first version' do
      it 'returns false' do
        expect(repository_object.can_discard_open_version?).to be(false)
      end
    end

    context 'when last closed version does not have cocina' do
      before do
        repository_object.close_version!
        repository_object.open_version!(description: 'draft')
      end

      it 'returns false' do
        expect(repository_object.can_discard_open_version?).to be(false)
      end
    end
  end

  describe '#discard_open_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    context 'when head version is discardable' do
      before do
        repository_object.close_version!
        repository_object.head_version.update!(cocina_version: Cocina::Models::VERSION)
        repository_object.open_version!(description: 'draft')
      end

      it 'discards draft' do
        expect { repository_object.discard_open_version! }
          .to change { repository_object.versions.count }
          .by(-1)
          .and change(repository_object, :head_version)
          .to(repository_object.versions.first)
          .and change(repository_object, :opened_version).to(nil)
      end
    end

    context 'when head version is not discardable' do
      it 'raises an error' do
        expect { repository_object.discard_open_version! }.to raise_error(described_class::VersionNotDiscardable)
      end
    end
  end

  describe '#reopen!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    context 'when head version is open' do
      it 'raises an error' do
        expect { repository_object.reopen! }.to raise_error(described_class::VersionAlreadyOpened)
      end
    end

    context 'when only the first version exists' do
      before do
        repository_object.close_version!
      end

      it 'sets last_closed_version to nil' do
        expect { repository_object.reopen! }
          .to change(repository_object, :last_closed_version)
          .to(nil)
          .and change(repository_object, :opened_version).to(repository_object.versions.first)
      end
    end

    context 'when others versions exists' do
      before do
        repository_object.close_version!
        repository_object.open_version!(description: 'second version')
        repository_object.close_version!
      end

      it 'sets last_closed_version' do
        expect { repository_object.reopen! }
          .to change(repository_object, :last_closed_version)
          .to(repository_object.versions.first)
          .and change(repository_object, :opened_version).to(repository_object.versions.last)
      end
    end
  end

  describe 'pre-populated attributes' do
    let(:druid) { 'druid:bc868mh7756' }

    before do
      repository_object = create(:repository_object, external_identifier: druid)
      repository_object.close_version!(description: 'Best first version ever')
      repository_object.open_version!(description: 'Best second version ever')
    end

    context 'when not pre-populated (i.e., lazy loading)' do
      it 'lazily loads the pre-populated attributes' do
        repository_object = described_class.find_by(external_identifier: druid)
        expect { repository_object.head_version_version_description }.to make_database_queries(count: 1)
        expect(repository_object.head_version_version_description).to eq('Best second version ever')
        expect(repository_object.head_version_version).to eq(2)
        expect { repository_object.opened_version_version_description }.to make_database_queries(count: 1)
        expect(repository_object.opened_version_version_description).to eq('Best second version ever')
        expect(repository_object.opened_version_version).to eq(2)
        expect { repository_object.last_closed_version_version_description }.to make_database_queries(count: 1)
        expect(repository_object.last_closed_version_version_description).to eq('Best first version ever')
        expect(repository_object.last_closed_version_version).to eq(1)
      end
    end

    context 'when pre-populated' do
      # rubocop:disable Layout/LineLength
      it 'uses the pre-populated attributes' do
        repository_object = described_class
                            .joins('INNER JOIN repository_object_versions AS head_version ON repository_objects.head_version_id = head_version.id')
                            .joins('LEFT OUTER JOIN repository_object_versions AS opened_version ON repository_objects.opened_version_id = opened_version.id')
                            .joins('LEFT OUTER JOIN repository_object_versions AS last_closed_version ON repository_objects.last_closed_version_id = last_closed_version.id')
                            .select(
                              'repository_objects.external_identifier',
                              'repository_objects.id',
                              'repository_objects.head_version_id',
                              'repository_objects.opened_version_id',
                              'repository_objects.last_closed_version_id',
                              'opened_version.version AS opened_version_version',
                              'opened_version.version_description AS opened_version_version_description',
                              'last_closed_version.version AS last_closed_version_version',
                              'last_closed_version.version_description AS last_closed_version_version_description',
                              'head_version.version AS head_version_version',
                              'head_version.version_description AS head_version_version_description'
                            )
                            .find_by(external_identifier: druid)
        expect { repository_object.head_version_version_description }.not_to make_database_queries
        expect(repository_object.head_version_version_description).to eq('Best second version ever')
        expect(repository_object.head_version_version).to eq(2)
        expect { repository_object.opened_version_version_description }.not_to make_database_queries
        expect(repository_object.opened_version_version_description).to eq('Best second version ever')
        expect(repository_object.opened_version_version).to eq(2)
        expect { repository_object.last_closed_version_version_description }.not_to make_database_queries
        expect(repository_object.last_closed_version_version_description).to eq('Best first version ever')
        expect(repository_object.last_closed_version_version).to eq(1)
      end
    end
    # rubocop:enable Layout/LineLength
  end
end
