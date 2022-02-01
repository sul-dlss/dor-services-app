# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  let(:minimal_cocina_collection) do
    Cocina::Models::Collection.new({
                                     cocinaVersion: '0.0.1',
                                     externalIdentifier: 'druid:hp308wm0436',
                                     type: Cocina::Models::Vocab.collection,
                                     label: 'Test Collection',
                                     version: 1,
                                     access: { access: 'world' }
                                   })
  end

  let(:cocina_collection) do
    Cocina::Models::Collection.new({
                                     cocinaVersion: '0.0.1',
                                     externalIdentifier: 'druid:hp308wm0436',
                                     type: Cocina::Models::Vocab.collection,
                                     label: 'Test Collection',
                                     version: 1,
                                     access: { access: 'world' },
                                     administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                     description: {
                                       title: [{ value: 'Test Collection' }],
                                       purl: 'https://purl.stanford.edu/hp308wm0436'
                                     },
                                     identification: { sourceId: 'googlebooks:999999' }
                                   })
  end

  describe 'to_cocina' do
    context 'with minimal collection' do
      let(:collection) { create(:collection) }

      it 'returns a Cocina::Model::Collection' do
        expect(collection.to_cocina).to eq(minimal_cocina_collection)
      end
    end

    context 'with complete Collection' do
      let(:collection) { create(:collection, :with_administrative, :with_collection_description, :with_collection_identification) }

      it 'returns a Cocina::Model::Collection' do
        expect(collection.to_cocina).to eq(cocina_collection)
      end
    end
  end

  describe 'from_cocina' do
    context 'with a minimal Collection' do
      let(:collection) { described_class.from_cocina(minimal_cocina_collection) }

      it 'returns a Collection' do
        expect(collection).to be_a(described_class)
        expect(collection.external_identifier).to eq(minimal_cocina_collection.externalIdentifier)
        expect(collection.cocina_version).to eq(minimal_cocina_collection.cocinaVersion)
        expect(collection.collection_type).to eq(minimal_cocina_collection.type)
        expect(collection.label).to eq(minimal_cocina_collection.label)
        expect(collection.version).to eq(minimal_cocina_collection.version)
        expect(collection.access).to eq(minimal_cocina_collection.access.to_h.with_indifferent_access)
        expect(collection.administrative).to be_nil
        expect(collection.description).to be_nil
        expect(collection.identification).to be_nil
      end
    end

    context 'with a complete Collection' do
      let(:collection) { described_class.from_cocina(cocina_collection) }

      it 'returns a Collection' do
        expect(collection).to be_a(described_class)
        expect(collection.external_identifier).to eq(cocina_collection.externalIdentifier)
        expect(collection.cocina_version).to eq(cocina_collection.cocinaVersion)
        expect(collection.collection_type).to eq(cocina_collection.type)
        expect(collection.label).to eq(cocina_collection.label)
        expect(collection.version).to eq(cocina_collection.version)
        expect(collection.access).to eq(cocina_collection.access.to_h.with_indifferent_access)
        expect(collection.administrative).to eq(cocina_collection.administrative.to_h.with_indifferent_access)
        expect(collection.description).to eq(cocina_collection.description.to_h.with_indifferent_access)
        expect(collection.identification).to eq(cocina_collection.identification.to_h.with_indifferent_access)
      end
    end
  end
end
