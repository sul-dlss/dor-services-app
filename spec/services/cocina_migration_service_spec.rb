# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaMigrationService do
  describe '#migrate' do
    let(:druid) { 'druid:hv992ry2431' }
    let(:fedora_object) { instance_double(Dor::Item, pid: druid, create_date: '2021-05-24T21:55:33.337Z', modified_date: '2022-05-24T21:55:33.337Z') }

    let(:cocina_object) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.image,
                              label: 'Test image',
                              version: 1,
                              access: {
                                view: 'world',
                                download: 'none',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: 'A test image' }],
                                purl: 'https://purl.stanford.edu/hv992ry2431'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: {
                                sourceId: 'googlebooks:999999',
                                barcode: '36105036289127'
                              },
                              externalIdentifier: druid,
                              structural: {})
    end

    let(:cocina_object_store) { instance_double(CocinaObjectStore) }

    before do
      allow(CocinaObjectStore).to receive(:new).and_return(cocina_object_store)
      allow(cocina_object_store).to receive(:cocina_to_ar_save)
      allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
    end

    context 'when already migrated' do
      before do
        allow(cocina_object_store).to receive(:ar_exists?).and_return(true)
      end

      it 'returns' do
        described_class.migrate(fedora_object)

        expect(Cocina::Mapper).not_to have_received(:build)
      end
    end

    context 'when migration needed' do
      before do
        allow(cocina_object_store).to receive(:ar_exists?).and_return(false)
      end

      it 'maps and persists' do
        described_class.migrate(fedora_object)
        expect(Cocina::Mapper).to have_received(:build).with(fedora_object)
        ar_cocina_object = Dro.find_by(external_identifier: druid)
        expect(ar_cocina_object.label).to eq('Test image')
        expect(ar_cocina_object.created_at).to eq('2021-05-24 21:55:33 UTC')
        expect(ar_cocina_object.updated_at).to eq('2022-05-24 21:55:33 UTC')
      end
    end
  end
end
