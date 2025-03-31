# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  include Dry::Monads[:result]

  let(:store) { described_class.new }

  describe '#find' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.find('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:repository_object) { create(:repository_object, :with_repository_object_version) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(store.find(repository_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:repository_object) { create(:repository_object, :admin_policy, :with_repository_object_version) }

      it 'returns Cocina::Models::AdminPolicy' do
        expect(store.find(repository_object.external_identifier))
          .to be_instance_of(Cocina::Models::AdminPolicyWithMetadata)
      end
    end

    context 'when ur_admin_policy is not found in datastore' do
      before do
        allow(Settings.ur_admin_policy).to receive(:druid).and_return('druid:bc123df4567')
        allow(Settings.enabled_features).to receive(:create_ur_admin_policy).and_return(true)
        allow(Indexer).to receive(:reindex)
      end

      it 'bootstraps' do
        expect(store.find('druid:bc123df4567').label).to eq('Ur-APO')
      end
    end

    context 'when object is a Collection' do
      let(:repository_object) { create(:repository_object, :collection, :with_repository_object_version) }

      it 'returns Cocina::Models::Collection' do
        expect(store.find(repository_object.external_identifier))
          .to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end
  end

  describe '#version' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.version('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is found in datastore' do
      let(:repository_object) { create(:repository_object, :with_repository_object_version, version: 5) }

      it 'returns version' do
        expect(store.version(repository_object.external_identifier)).to eq(5)
      end
    end
  end

  describe '#find_by_source_id' do
    subject(:find_by_source) { store.find_by_source_id(source_id) }

    let(:source_id) { repository_object.head_version.identification['sourceId'] }

    context 'when object is not found in datastore' do
      let(:source_id) { 'sul:abc123' }

      it 'raises' do
        expect { find_by_source }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is found in datastore' do
      let(:repository_object) { create(:repository_object, :with_repository_object_version) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(find_by_source).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end
  end

  describe '#exists?' do
    subject { store.exists?(druid) }

    context 'when the object is found in the datastore' do
      let(:druid) { repository_object.external_identifier }
      let(:repository_object) { create(:repository_object, :with_repository_object_version) }

      it { is_expected.to be true }
    end

    context 'when the object is not found in then datastore' do
      let(:druid) { 'druid:bc123df4567' }

      it { is_expected.to be false }
    end
  end

  describe '#exists!' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.exists!('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is found in datastore' do
      let(:repository_object) { create(:repository_object, :with_repository_object_version) }

      it 'returns true' do
        expect(store.exists!(repository_object.external_identifier)).to be(true)
      end
    end
  end
end
