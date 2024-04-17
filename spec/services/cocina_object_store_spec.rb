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
        allow(Indexer).to receive(:reindex)
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

    context 'when object is a RepositoryObject' do
      let(:version_attributes) { RepositoryObjectVersion.to_model_hash(build(:dro, id: repo_object.external_identifier)) }
      let(:repo_object) { create(:repository_object) }

      before do
        repo_object.head_version.update!(version_attributes)
      end

      it 'returns Cocina::Models::DRO' do
        expect(store.find(repo_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when enabled_features.repository_object_test is enabled' do
      let(:ar_cocina_object) { create(:ar_dro) }
      let(:repo_object) { create(:repository_object, external_identifier: ar_cocina_object.external_identifier) }

      before do
        allow(Settings.enabled_features).to receive(:repository_object_test).and_return true
        allow(Honeybadger).to receive(:notify)
        repo_object.head_version.update!(version_attributes)
      end

      context "when objects don't match" do
        let(:version_attributes) { RepositoryObjectVersion.to_model_hash(build(:dro, id: repo_object.external_identifier)) }

        it 'returns Cocina::Models::DRO and reports a diff' do
          expect(store.find(repo_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Honeybadger).to have_received(:notify)
            .with('Comparison of RepositoryObject with legacy object failed.',
                  context: { druid: ar_cocina_object.external_identifier })
        end
      end

      context 'when objects match' do
        let(:version_attributes) { RepositoryObjectVersion.to_model_hash(ar_cocina_object.to_cocina) }

        before do
          repo_object.head_version.update!(updated_at: 1.day.ago)
        end

        it "doesn't report a diff" do
          expect(store.find(repo_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Honeybadger).not_to have_received(:notify)
        end
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

    context "when repository_object_test is enabled and versions don't match" do
      let(:ar_cocina_object) { create(:ar_dro, version: 5) }

      before do
        allow(Honeybadger).to receive(:notify)
        create(:repository_object, external_identifier: ar_cocina_object.external_identifier)
        allow(Settings.enabled_features).to receive(:repository_object_test).and_return true
      end

      it 'returns old version and logs to Honeybadger' do
        expect(store.version(ar_cocina_object.external_identifier)).to eq(5)
        expect(Honeybadger).to have_received(:notify)
          .with("Version from RepositoryObjectVersion doesn't match version in legacy store.",
                context: { druid: ar_cocina_object.external_identifier, version_from_repository_object: 1, version_from_ar_cocina_object: 5 })
      end
    end

    context 'when RepositoryObject is found' do
      subject { store.version(repository_object.external_identifier) }

      let(:repository_object) { create(:repository_object) }

      before do
        create(:ar_dro, external_identifier: repository_object.external_identifier, version: 5)
      end

      it { is_expected.to eq 1 }
    end
  end

  describe '#find_by_source_id' do
    subject(:find_by_source) { store.find_by_source_id(source_id) }

    let(:source_id) { ar_cocina_object.identification['sourceId'] }

    context 'when object is not found in datastore' do
      let(:source_id) { 'sul:abc123' }

      it 'raises' do
        expect { find_by_source }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(find_by_source).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns Cocina::Models::Collection' do
        expect(find_by_source).to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end

    context 'when object is a RepositoryObject' do
      let(:version_attributes) { RepositoryObjectVersion.to_model_hash(build(:dro, id: repo_object.external_identifier)) }
      let(:repo_object) { create(:repository_object) }
      let(:source_id) { repo_object.head_version.identification['sourceId'] }

      before do
        repo_object.head_version.update!(version_attributes)
      end

      it 'returns Cocina::Models::DRO' do
        expect(find_by_source).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when enabled_features.repository_object_test is enabled' do
      let(:ar_cocina_object) { create(:ar_dro) }
      let(:repo_object) { create(:repository_object, external_identifier: ar_cocina_object.external_identifier) }

      before do
        allow(Settings.enabled_features).to receive(:repository_object_test).and_return true
        allow(Honeybadger).to receive(:notify)
        repo_object.head_version.update!(version_attributes)
      end

      context "when objects don't match" do
        let(:version_attributes) { RepositoryObjectVersion.to_model_hash(build(:dro, id: repo_object.external_identifier, source_id:)) }

        it 'returns Cocina::Models::DRO and reports a diff' do
          expect(find_by_source).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Honeybadger).to have_received(:notify)
            .with('Comparison of RepositoryObject with legacy object failed.',
                  context: { source_id: })
        end
      end

      context 'when objects match' do
        let(:version_attributes) { RepositoryObjectVersion.to_model_hash(ar_cocina_object.to_cocina) }

        it "doesn't report a diff" do
          expect(find_by_source).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end
  end

  describe '#exists?' do
    context 'when repository_object is false' do
      context 'when object is not found in datastore' do
        it 'returns false' do
          expect(store.exists?('druid:bc123df4567')).to be(false)
        end
      end

      context 'when type is specified and object is found in datastore' do
        let(:ar_cocina_object) { create(:ar_dro) }

        it 'returns true' do
          expect(store.exists?(ar_cocina_object.external_identifier, type: CocinaObjectStore::DRO)).to be(true)
        end
      end

      context 'when type is specified and object is found in datastore but different type' do
        let(:ar_cocina_object) { create(:ar_dro) }

        it 'returns false' do
          expect(store.exists?(ar_cocina_object.external_identifier, type: [CocinaObjectStore::COLLECTION, CocinaObjectStore::ADMIN_POLICY])).to be(false)
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

    context 'when repository_object_find is true' do
      subject { store.exists?(druid) }

      before do
        allow(Settings.enabled_features).to receive(:repository_object_find).and_return(true)
      end

      context 'when the item exists' do
        let(:druid) { create(:repository_object).external_identifier }

        it { is_expected.to be true }
      end

      context "when the item doesn't exist" do
        let(:druid) { 'druid:bc123df4567' }

        it { is_expected.to be false }
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
end
