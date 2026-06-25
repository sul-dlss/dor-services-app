# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::MarcService do
  let(:marc_service) { described_class.new(folio_instance_hrid: 'a123', barcode: nil) }
  let(:marc_record) do
    MARC::Record.new.tap do |record|
      record << MARC::DataField.new('245', '1', '0', ['a', 'Gaudy night /'], ['c', 'by Dorothy L. Sayers.'])
    end
  end
  let(:marc_hash) do
    { leader: '          22        4500',
      fields: [
        { '245': {
          ind1: '1',
          ind2: '0',
          subfields: [
            {
              a: 'Gaudy night /'
            },
            {
              c: 'by Dorothy L. Sayers.'
            }
          ]
        } },
        { '001' => 'a123' },
        { '003' => 'FOLIO' }
      ] }.with_indifferent_access
  end
  let(:fetcher) { instance_double(Catalog::SourceStorageFetcher, fetch: marc_record.to_hash) }
  let(:barcode) { nil }

  before do
    allow(Catalog::SourceStorageFetcher).to receive(:new).and_return(fetcher)
  end

  describe '#marc' do
    before do
      allow(described_class).to receive(:new).and_call_original
    end

    it 'returns MARC data from FOLIO' do
      described_class.marc(folio_instance_hrid: 'a123', barcode: nil)
      expect(described_class).to have_received(:new).with(folio_instance_hrid: 'a123', barcode: nil)
      expect(Catalog::SourceStorageFetcher).to have_received(:new).with(folio_instance_hrid: 'a123')
      expect(fetcher).to have_received(:fetch)
    end

    context 'when Folio record is found' do
      before do
        allow(fetcher).to receive(:fetch).and_raise(FolioClient::ResourceNotFound)
      end

      it 'raises CatalogRecordNotFoundError when FOLIO record not found' do
        expect do
          marc_service.marc
        end.to raise_error(Catalog::Errors::RecordNotFoundError,
                           /Catalog record not found for HRID 'a123' or barcode ''/)
      end
    end

    context 'when no folio_instance_hrid is provided and fetch fails' do
      let(:marc_service) { described_class.new }

      before do
        allow(Catalog::SourceStorageFetcher).to receive(:new).and_call_original
        allow(FolioClient).to receive(:fetch_hrid).with(barcode:).and_return(nil)
        allow(FolioClient).to receive(:fetch_marc_hash).with(instance_hrid: nil).and_raise(FolioClient::MultipleResourcesFound)
      end

      it 'raises a RecordNotFoundError' do
        expect { marc_service.marc }.to raise_error(
          Catalog::Errors::RecordNotFoundError,
          /Catalog record not found for HRID '' or barcode ''/
        )
      end
    end

    context 'when barcode is provided' do
      let(:barcode) { '123456789' }
      let(:marc_service) { described_class.new(folio_instance_hrid: nil, barcode:) }

      before do
        allow(FolioClient).to receive(:fetch_hrid).with(barcode:).and_return('a123')
      end

      it 'requests the record by barcode' do
        expect(marc_service.marc).to eq marc_hash
        expect(Catalog::SourceStorageFetcher).to have_received(:new).with(folio_instance_hrid: 'a123')
      end
    end
  end
end
