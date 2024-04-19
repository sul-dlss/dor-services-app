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
        repository_object.update(last_closed_version: repository_object.versions.create!(version: 2, version_description: 'closed'))
        repository_object.update(opened_version: repository_object.versions.create!(version: 3, version_description: 'draft'))
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

  describe 'object version scope meta-programming' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    before do
      repository_object.update(head_version: repository_object.versions.first)
      allow(RepositoryObjectVersion).to receive(:in_virtual_objects).and_return([])
    end

    it 'sends the query to the repository object version class' do
      described_class.currently_in_virtual_objects('druid:xz456jk0987')
      expect(RepositoryObjectVersion).to have_received(:in_virtual_objects).with('druid:xz456jk0987')
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
      end
    end
  end

  describe '#close_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    let(:description) { 'my closed version' }

    it 'sets the closed_at field' do
      expect { repository_object.close_version! }.to change(repository_object.head_version, :closed_at).to(instance_of(ActiveSupport::TimeWithZone))
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
end
