# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  let(:druid) { 'druid:hp308wm0436' }

  let(:cocina_collection) do
    Cocina::Models::Collection.new({
                                     cocinaVersion: Cocina::Models::VERSION,
                                     externalIdentifier: druid,
                                     type: Cocina::Models::ObjectType.collection,
                                     label: 'Test Collection',
                                     version: 1,
                                     access: { view: 'world' },
                                     description: {
                                       title: [{ value: 'Test Collection' }],
                                       purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                     },
                                     administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                     identification: { sourceId: source_id }
                                   })
  end

  let(:source_id) { 'googlebooks:9999999' }

  describe 'to_cocina' do
    let(:collection) { create(:ar_collection, external_identifier: druid) }
    let(:source_id) { collection.identification['sourceId'] }

    it 'returns a Cocina::Model::Collection' do
      expect(collection.to_cocina).to eq(cocina_collection)
    end
  end

  describe 'from_cocina' do
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

  describe 'sourceId uniqueness' do
    let(:cocina_object1) do
      cocina_collection.new(identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0031' })
    end

    context 'when sourceId is unique' do
      let(:cocina_object2) do
        cocina_collection.new(
          externalIdentifier: 'druid:dd645sg2172',
          identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0032' },
          description: {
            title: [{ value: 'Test Collection' }],
            purl: 'https://purl.stanford.edu/dd645sg2172'
          }
        )
      end

      it 'does not raise' do
        described_class.upsert_cocina(cocina_object1)
        described_class.upsert_cocina(cocina_object2)
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object2) do
        cocina_collection.new(
          externalIdentifier: 'druid:dd645sg2172',
          identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0031' },
          description: {
            title: [{ value: 'Test Collection' }],
            purl: 'https://purl.stanford.edu/dd645sg2172'
          }
        )
      end

      it 'raises' do
        described_class.upsert_cocina(cocina_object1)
        expect { described_class.upsert_cocina(cocina_object2) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe 'presence validation' do
    subject(:collection) { described_class.create }

    it 'tells you if fields are missing' do
      expect(collection.errors.attribute_names).to match_array %i[external_identifier
                                                                  cocina_version
                                                                  version label access administrative
                                                                  description identification]
    end
  end
end
