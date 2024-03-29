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
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns Cocina::Models::AdminPolicy' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::AdminPolicyWithMetadata)
      end
    end

    context 'when ur_admin_policy is not found in datastore' do
      before do
        allow(Settings.ur_admin_policy).to receive(:druid).and_return('druid:bc123df4567')
        allow(Settings.enabled_features).to receive(:create_ur_admin_policy).and_return(true)
      end

      it 'bootstraps' do
        expect(store.find('druid:bc123df4567').label).to eq('Ur-APO')
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns Cocina::Models::Collection' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end
  end

  describe '#version' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.version('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro, version: 5) }

      it 'returns version' do
        expect(store.version(ar_cocina_object.external_identifier)).to eq(5)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy, version: 2) }

      it 'returns version' do
        expect(store.version(ar_cocina_object.external_identifier)).to eq(2)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection, version: 4) }

      it 'returns version' do
        expect(store.version(ar_cocina_object.external_identifier)).to eq(4)
      end
    end
  end

  describe '#find_by_source_id' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.find('sul:abc123') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(store.find_by_source_id(ar_cocina_object.identification['sourceId'])).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns Cocina::Models::Collection' do
        expect(store.find_by_source_id(ar_cocina_object.identification['sourceId'])).to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end
  end

  describe '#exists?' do
    context 'when object is not found in datastore' do
      it 'returns false' do
        expect(store.exists?('druid:bc123df4567')).to be(false)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns true' do
        expect(store.exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns true' do
        expect(store.exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns true' do
        expect(store.exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end
  end

  describe '#exists!' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.exists!('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns true' do
        expect(store.exists!(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns true' do
        expect(store.exists!(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns true' do
        expect(store.exists!(ar_cocina_object.external_identifier)).to be(true)
      end
    end
  end

  describe '#destroy' do
    let!(:dro) { create(:ar_dro) }

    before do
      allow(Notifications::ObjectDeleted).to receive(:publish)
    end

    it 'destroys the object' do
      described_class.destroy(dro.external_identifier)
      expect(Dro).not_to exist(dro.external_identifier)
      expect(Notifications::ObjectDeleted).to have_received(:publish)
    end
  end
end
