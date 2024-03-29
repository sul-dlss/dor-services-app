# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConstituentService do
  describe '#add' do
    let(:constituent_druids) { ['druid:xh235dd9059'] }
    let(:event_factory) { class_double(EventFactory) }
    let(:item_errors) { {} }
    let(:mock_item) { build(:dro) }
    let(:open_for_versioning) { true }
    let(:service) { described_class.new(virtual_object_druid:, event_factory:) }
    let(:virtual_object) { build(:dro_with_metadata, id: virtual_object_druid) }
    let(:virtual_object_druid) { 'druid:bc123df4567' }

    before do
      allow(ItemQueryService).to receive_messages(find_combinable_item: virtual_object, validate_combinable_items: item_errors)
      allow(VersionService).to receive_messages(open?: open_for_versioning, open: virtual_object)
      allow(VersionService).to receive(:close)
      allow(ResetContentMetadataService).to receive(:reset).and_return(virtual_object)
      allow(UpdateObjectService).to receive(:update)
      allow(CocinaObjectStore).to receive(:find).and_return(mock_item)
      allow(SynchronousIndexer).to receive(:reindex_remotely_from_cocina)
      allow(Publish::MetadataTransferService).to receive(:publish)
    end

    context 'when one or more items are not combinable' do
      let(:item_errors) { { virtual_object_druid => ["Item #{virtual_object_druid} is dark"] } }

      it 'returns hash with errors' do
        expect(service.add(constituent_druids:)).to eq(item_errors)
        expect(VersionService).not_to have_received(:open?)
        expect(VersionService).not_to have_received(:open)
        expect(VersionService).not_to have_received(:close)
        expect(ResetContentMetadataService).not_to have_received(:reset)
        expect(UpdateObjectService).not_to have_received(:update)
        expect(SynchronousIndexer).not_to have_received(:reindex_remotely_from_cocina)
      end
    end

    context 'when virtual object is not open for versioning' do
      let(:open_for_versioning) { false }

      it 'opens virtual object for versioning' do
        service.add(constituent_druids:)
        expect(VersionService).to have_received(:open).with(cocina_object: virtual_object,
                                                            description: ConstituentService::VERSION_DESCRIPTION,
                                                            significance: ConstituentService::VERSION_SIGNIFICANCE,
                                                            event_factory:)
      end
    end

    it 'resets structural metadata of virtual object to given constituents' do
      service.add(constituent_druids:)
      expect(ResetContentMetadataService).to have_received(:reset).once
    end

    it 'closes open version' do
      service.add(constituent_druids:)
      expect(VersionService).to have_received(:close).with(druid: virtual_object.externalIdentifier, version: virtual_object.version, event_factory:)
    end

    it 'indexes virtual object synchronously' do
      service.add(constituent_druids:)
      expect(SynchronousIndexer).to have_received(:reindex_remotely_from_cocina).once
    end

    it 'publishes constituents' do
      service.add(constituent_druids:)
      expect(CocinaObjectStore).to have_received(:find).exactly(constituent_druids.count).times
      expect(Publish::MetadataTransferService).to have_received(:publish).exactly(constituent_druids.count).times
    end

    it 'returns nil' do
      expect(service.add(constituent_druids:)).to be_nil
    end
  end
end
