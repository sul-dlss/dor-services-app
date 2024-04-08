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

    context 'when head and open point at same version' do
      before do
        repository_object.save # we need at least one persisted version so we can run this validation
        repository_object.open = repository_object.head = repository_object.versions.first
      end

      it { is_expected.not_to be_valid }
    end

    # NOTE: I'm not sure this can currently happen?
    context 'when current points at something other than head or open' do
      before do
        repository_object.save # we need at least one persisted version so we can run this validation
        repository_object.update(current: repository_object.versions.first)
        repository_object.update(head: repository_object.versions.create!(version: 2, version_description: 'closed'))
        repository_object.update(open: repository_object.versions.create!(version: 3, version_description: 'draft'))
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
      repository_object.update(current: repository_object.versions.first)
    end

    it 'does not raise on destroy' do
      expect { repository_object.destroy }.not_to raise_error
    end
  end

  describe 'object version scope meta-programming' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    before do
      repository_object.update(current: repository_object.versions.first)
      allow(RepositoryObjectVersion).to receive(:in_virtual_objects).and_return([])
    end

    it 'sends the query to the repository object version class' do
      described_class.currently_in_virtual_objects('druid:xz456jk0987')
      expect(RepositoryObjectVersion).to have_received(:in_virtual_objects).with('druid:xz456jk0987')
    end
  end

  describe '#open_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    it 'raises when version is already open' do
      expect { repository_object.open_version! }.to raise_error(described_class::VersionAlreadyOpened)
    end

    context 'when closed' do
      before do
        repository_object.close_version!
      end

      it 'creates a new version' do
        expect { repository_object.open_version! }.to change(RepositoryObjectVersion, :count).by(1)
      end

      it 'auto-increments the version number' do
        repository_object.open_version!
        expect(repository_object.versions.last.version).to eq(2)
      end

      it 'updates the current pointer' do
        repository_object.open_version!
        expect(repository_object.current).to eq(repository_object.versions.find_by(version: 2))
      end

      it 'updates the open pointer' do
        repository_object.open_version!
        expect(repository_object.open).to eq(repository_object.versions.find_by(version: 2))
      end
    end
  end

  describe '#close_version!' do
    subject(:repository_object) { create(:repository_object, **attrs) }

    it 'sets the closed_at field' do
      expect { repository_object.close_version! }.to change(repository_object.current, :closed_at).to(instance_of(ActiveSupport::TimeWithZone))
    end

    it 'updates the current pointer' do
      repository_object.close_version!
      expect(repository_object.current).to eq(repository_object.versions.find_by(version: 1))
    end

    it 'updates the head pointer' do
      repository_object.close_version!
      expect(repository_object.head).to eq(repository_object.versions.find_by(version: 1))
    end

    it 'resets the open pointer' do
      repository_object.close_version!
      expect(repository_object.open).to be_nil
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
end
