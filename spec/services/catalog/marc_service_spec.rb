# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::MarcService do
  let(:marc_service) { described_class.new(folio_instance_hrid: 'a123') }
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
        } }
      ] }.with_indifferent_access
  end
  let(:folio_reader) { instance_double(Catalog::FolioReader) }
  let(:barcode) { nil }

  before do
    allow(Catalog::FolioReader).to receive(:new).and_return(folio_reader)
    allow(folio_reader).to receive(:to_marc).and_return(marc_record)
  end

  describe '#marc' do
    it 'returns MARC data from FOLIO' do
      expect(marc_service.marc).to eq marc_hash
      expect(Catalog::FolioReader).to have_received(:new).with(folio_instance_hrid: 'a123', barcode: nil)
      expect(folio_reader).to have_received(:to_marc)
    end

    it 'raises CatalogRecordNotFoundError when FOLIO record not found' do
      allow(folio_reader).to receive(:to_marc).and_raise(FolioClient::ResourceNotFound)

      expect do
        marc_service.marc
      end.to raise_error(Catalog::MarcService::CatalogRecordNotFoundError,
                         /Catalog record not found. HRID: a123 \| Barcode: /)
    end

    context 'when barcode is provided' do
      let(:barcode) { '123456789' }
      let(:marc_service) { described_class.new(folio_instance_hrid: nil, barcode:) }

      it 'requests record by barcode' do
        expect(marc_service.marc).to eq marc_hash
        expect(Catalog::FolioReader).to have_received(:new).with(folio_instance_hrid: nil, barcode: '123456789')
      end
    end
  end
end
