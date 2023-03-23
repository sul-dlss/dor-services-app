# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::FolioWriter do
  subject(:folio_writer) { described_class.new(cocina_object:, marc_856_data:) }

  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }

  let(:marc_856_data) do
    {
      indicators: '41',
      subfields: [
        { code: 'u', value: 'https://purl.stanford.edu/bc123dg9393' },
        { code: 'x', value: 'SDR-PURL' },
        { code: 'x', value: 'item' },
        { code: 'x', value: 'barcode:36105216275185' },
        { code: 'x', value: 'rights:world' }
      ]
    }
  end

  let(:folio_response_json) do
    { parsedRecordId: '1ab23862-46db-4da9-af5b-633adbf5f90f',
      fields:
      [{ tag: '001', content: 'in00000000067', isProtected: true },
       { tag: '100', content: '$a Scully, Dana, $e author.', indicators: ['1', '\\'], isProtected: false },
       { tag: '856',
         content: '$u https://purl.stanford.edu/bc123dg9393' },
       { tag: '999',
         content: '$s 1281ae0b-548b-49e3-b740-050f28e6d57f $i 5108040a-65bc-40ed-bd50-265958301ce4',
         indicators: ['f', 'f'],
         isProtected: true }],
      updateInfo: {
        updateDate: '2023-02-14T10:39:19.642Z'
      } }.deep_stringify_keys
  end

  let(:updated_marc_json) do
    { parsedRecordId: '1ab23862-46db-4da9-af5b-633adbf5f90f',
      fields:
      [{ tag: '001', content: 'in00000000067', isProtected: true },
       { tag: '100', content: '$a Scully, Dana, $e author.', indicators: ['1', '\\'], isProtected: false },
       { tag: '999',
         content: '$s 1281ae0b-548b-49e3-b740-050f28e6d57f $i 5108040a-65bc-40ed-bd50-265958301ce4',
         indicators: ['f', 'f'],
         isProtected: true },
       { tag: '856',
         content: '$u https://purl.stanford.edu/bc123dg9393 $x SDR-PURL $x item $x barcode:36105216275185 $x rights:world',
         indicators: ['4', '1'],
         isProtected: false }],
      updateInfo: {
        updateDate: '2023-02-14T10:39:19.642Z'
      } }.deep_stringify_keys
  end

  let(:unreleased_marc_json) do
    { parsedRecordId: '1ab23862-46db-4da9-af5b-633adbf5f90f',
      fields:
      [{ tag: '001', content: 'in00000000067', isProtected: true },
       { tag: '100', content: '$a Scully, Dana, $e author.', indicators: ['1', '\\'], isProtected: false },
       { tag: '999',
         content: '$s 1281ae0b-548b-49e3-b740-050f28e6d57f $i 5108040a-65bc-40ed-bd50-265958301ce4',
         indicators: ['f', 'f'],
         isProtected: true }],
      updateInfo: {
        updateDate: '2023-02-14T10:39:19.642Z'
      } }.deep_stringify_keys
  end

  describe '.save' do
    let(:cocina_object) { build(:dro, id: druid).new(identification:) }
    let(:release_data) { { 'Searchworks' => { 'release' => true } } }
    let(:hrid) { 'a8832162' }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(FolioClient).to receive(:edit_marc_json).and_yield(folio_response_json)
      allow(ReleaseTags).to receive(:for).and_return(release_data)
    end

    context 'when a single catalog record has been released to Searchworks' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: hrid
            }
          ]
        }
      end

      it 'updates the MARC record' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
        expect(folio_response_json).to eq(updated_marc_json)
      end
    end

    context 'when a single catalog record id that has not been released to Searchworks' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: hrid
            }
          ]
        }
      end
      let(:release_data) { {} }

      it 'updates the MARC record and does not include the 856' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
        expect(folio_response_json).to eq(unreleased_marc_json)
      end
    end

    context 'when previous and current catalog record ids' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'previous folio',
              catalogRecordId: 'a8832160'
            },
            {
              catalog: 'folio',
              catalogRecordId: 'a8832162'
            }
          ]
        }
      end

      it 'updates the MARC record' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832160')
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832162')
        expect(folio_response_json).to eq(updated_marc_json)
      end
    end

    context 'when only previous catalog record ids' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'previous folio',
              catalogRecordId: 'a8832160'
            },
            {
              catalog: 'previous folio',
              catalogRecordId: 'a8832161'
            }
          ]
        }
      end

      let(:marc_856_data) do
        {
          indicators: '41',
          subfields: [
            { code: 'z', value: nil }
          ]
        }
      end

      it 'updates the MARC record to not include the 856' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).twice
        expect(folio_response_json).to eq(unreleased_marc_json)
      end
    end
  end
end
