# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConstituentService do
  describe '#add' do
    let(:constituent_druids) { ['druid:xh235dd9059'] }
    let(:event_factory) { class_double(EventFactory) }
    let(:item_errors) { {} }
    let(:mock_item) do
      Cocina::Models::DRO.new(
        type: Cocina::Models::ObjectType.object,
        label: 'Dummy',
        version: 1,
        administrative: { hasAdminPolicy: 'druid:dd999df2345' },
        access: {},
        description: {
          title: [{ value: 'Dummy' }],
          purl: 'https://purl.stanford.edu/kh875jg9754'
        },
        externalIdentifier: 'druid:kh875jg9754',
        identification: { sourceId: 'sul:123' },
        structural: {}
      )
    end
    let(:open_for_versioning) { true }
    let(:service) { described_class.new(virtual_object_druid: virtual_object_druid, event_factory: event_factory) }
    let(:virtual_object) do
      Cocina::Models::DRO.new(
        type: Cocina::Models::ObjectType.object,
        label: 'Dummy',
        version: 1,
        administrative: { hasAdminPolicy: 'druid:dd999df2345' },
        access: {},
        description: {
          title: [{ value: 'Dummy' }],
          purl: "https://purl.stanford.edu/#{virtual_object_druid.delete_prefix('druid:')}"
        },
        externalIdentifier: virtual_object_druid,
        identification: { sourceId: 'sul:123' },
        structural: {}
      )
    end
    let(:virtual_object_druid) { 'druid:bc123df4567' }
    let(:created_at) { Time.zone.now }
    let(:updated_at) { Time.zone.now }
    let(:virtual_object_with_metadata) { Cocina::Models.with_metadata(virtual_object, '1', created: created_at, modified: updated_at) }

    before do
      allow(ItemQueryService).to receive(:find_combinable_item).and_return(virtual_object_with_metadata)
      allow(ItemQueryService).to receive(:validate_combinable_items).and_return(item_errors)
      allow(VersionService).to receive(:open?).and_return(open_for_versioning)
      allow(VersionService).to receive(:open)
      allow(VersionService).to receive(:close)
      allow(ResetContentMetadataService).to receive(:reset)
      allow(CocinaObjectStore).to receive(:save)
      allow(CocinaObjectStore).to receive(:find).and_return(mock_item)
      allow(SynchronousIndexer).to receive(:reindex_remotely_from_cocina)
      allow(Publish::MetadataTransferService).to receive(:publish)
      allow(Dor::UpdateMarcRecordService).to receive(:update)
    end

    context 'when one or more items are not combinable' do
      let(:item_errors) { { virtual_object_druid => ["Item #{virtual_object_druid} is dark"] } }

      it 'returns hash with errors' do
        expect(service.add(constituent_druids: constituent_druids)).to eq(item_errors)
        expect(VersionService).not_to have_received(:open?)
        expect(VersionService).not_to have_received(:open)
        expect(VersionService).not_to have_received(:close)
        expect(ResetContentMetadataService).not_to have_received(:reset)
        expect(CocinaObjectStore).not_to have_received(:save)
        expect(SynchronousIndexer).not_to have_received(:reindex_remotely_from_cocina)
      end
    end

    context 'when virtual object is not open for versioning' do
      let(:open_for_versioning) { false }

      it 'opens virtual object for versioning' do
        service.add(constituent_druids: constituent_druids)
        expect(VersionService).to have_received(:open).once
      end
    end

    it 'resets structural metadata of virtual object to given constituents' do
      service.add(constituent_druids: constituent_druids)
      expect(ResetContentMetadataService).to have_received(:reset).once
    end

    it 'closes open version' do
      service.add(constituent_druids: constituent_druids)
      expect(VersionService).to have_received(:close).once
    end

    it 'indexes virtual object synchronously' do
      service.add(constituent_druids: constituent_druids)
      expect(SynchronousIndexer).to have_received(:reindex_remotely_from_cocina).once
    end

    it 'publishes constituents' do
      service.add(constituent_druids: constituent_druids)
      expect(CocinaObjectStore).to have_received(:find).exactly(constituent_druids.count).times
      expect(Publish::MetadataTransferService).to have_received(:publish).exactly(constituent_druids.count).times
      expect(Dor::UpdateMarcRecordService).not_to have_received(:update)
    end

    context 'when constituents have catkeys' do
      let(:mock_item) do
        Cocina::Models::DRO.new(
          type: Cocina::Models::ObjectType.object,
          label: 'Dummy',
          version: 1,
          administrative: { hasAdminPolicy: 'druid:dd999df2345' },
          access: {},
          externalIdentifier: 'druid:kh875jg9754',
          description: {
            title: [{ value: 'Dummy' }],
            purl: 'https://purl.stanford.edu/kh875jg9754'
          },
          identification: {
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: '12345'
              }
            ],
            sourceId: 'sul:123'
          },
          structural: {}
        )
      end

      it 'updates MARC' do
        service.add(constituent_druids: constituent_druids)
        expect(Dor::UpdateMarcRecordService).to have_received(:update).exactly(constituent_druids.count).times
      end
    end

    it 'returns nil' do
      expect(service.add(constituent_druids: constituent_druids)).to be_nil
    end
  end
end
