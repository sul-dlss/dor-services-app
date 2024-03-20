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

  let(:source_record) do
    { fields: [
      { '001': 'a666' },
      { '856': { ind1: '4',
                 ind2: '1',
                 subfields: [{ u: 'https://purl.stanford.edu/bc123dg9393' },
                             { x: 'SDR-PURL' },
                             { x: 'item' },
                             { x: 'barcode:36105216275185' },
                             { x: 'rights:world' }] } }
    ] }.deep_stringify_keys
  end

  let(:instance_record) do
    {
      id: 'db80714e-398c-56f5-b228-7ad0874107cf',
      _version: '36',
      hrid: 'a666',
      electronicAccess: [{
        uri: 'https://purl.stanford.edu/bc123dg9393',
        linkText: nil
      }]
    }.deep_stringify_keys
  end

  let(:instance_record_unreleased) do
    {
      id: 'db80714e-398c-56f5-b228-7ad0874107cf',
      _version: '36',
      hrid: 'a666',
      electronicAccess: []
    }.deep_stringify_keys
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
    let(:release_data) { true }
    let(:hrid) { 'a8832162' }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(FolioClient).to receive(:edit_marc_json).and_yield(folio_response_json)
      allow(ReleaseTags).to receive(:released_to_searchworks?).and_return(release_data)
      allow(FolioClient).to receive_messages(fetch_instance_info: instance_record, fetch_marc_hash: source_record)
      allow(Honeybadger).to receive(:notify)
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
        expect(FolioClient).to have_received(:fetch_marc_hash).with(instance_hrid: hrid)
        expect(FolioClient).to have_received(:fetch_instance_info).with(hrid:)
        expect(folio_response_json).to eq(updated_marc_json)
      end

      context 'when record not found' do
        before do
          allow(FolioClient).to receive(:edit_marc_json).and_raise(FolioClient::ResourceNotFound)
        end

        it 'raises' do
          expect { folio_writer.save }.to raise_error(FolioClient::ResourceNotFound)
        end
      end

      context 'when existing 856 PURL uses http://' do
        let(:folio_response_json) do
          { parsedRecordId: '1ab23862-46db-4da9-af5b-633adbf5f90f',
            fields:
            [{ tag: '001', content: 'in00000000067', isProtected: true },
             { tag: '100', content: '$a Scully, Dana, $e author.', indicators: ['1', '\\'], isProtected: false },
             { tag: '856',
               content: '$u http://purl.stanford.edu/bc123dg9393' },
             { tag: '999',
               content: '$s 1281ae0b-548b-49e3-b740-050f28e6d57f $i 5108040a-65bc-40ed-bd50-265958301ce4',
               indicators: ['f', 'f'],
               isProtected: true }],
            updateInfo: {
              updateDate: '2023-02-14T10:39:19.642Z'
            } }.deep_stringify_keys
        end

        it 'updates the MARC record with https PURL' do
          folio_writer.save
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(FolioClient).to have_received(:fetch_marc_hash).with(instance_hrid: hrid)
          expect(FolioClient).to have_received(:fetch_instance_info).with(hrid:)
          expect(folio_response_json).to eq(updated_marc_json)
        end
      end

      context 'when instance record does not show updates at first' do
        let(:instance_record_first_lookup) do
          {
            id: 'db80714e-398c-56f5-b228-7ad0874107cf',
            _version: '36',
            hrid: 'a10',
            electronicAccess: []
          }.deep_stringify_keys
        end

        before do
          allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record_first_lookup, instance_record)
          allow(FolioClient).to receive(:fetch_marc_hash).and_return(source_record)
          allow(Rails.logger).to receive(:warn)
        end

        it 'updates the MARC record and retries lookup once' do
          folio_writer.save
          expect(FolioClient).to have_received(:fetch_instance_info).twice
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(Rails.logger).to have_received(:warn).once
          expect(folio_response_json).to eq(updated_marc_json)
        end
      end

      context 'when instance and source records do not show updates at first' do
        let(:instance_record_first_lookup) do
          {
            id: 'db80714e-398c-56f5-b228-7ad0874107cf',
            _version: '36',
            hrid: 'a10',
            electronicAccess: []
          }.deep_stringify_keys
        end
        let(:source_record_first_lookup) do
          { fields: [
            { '001': 'a666' }
          ] }.deep_stringify_keys
        end

        before do
          allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record_first_lookup, instance_record, instance_record)
          allow(FolioClient).to receive(:fetch_marc_hash).and_return(source_record_first_lookup, source_record)
          allow(Rails.logger).to receive(:warn)
        end

        it 'updates the MARC record and retries lookups' do
          folio_writer.save
          expect(FolioClient).to have_received(:fetch_instance_info).exactly(3).times
          expect(FolioClient).to have_received(:fetch_marc_hash).twice
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(Rails.logger).to have_received(:warn).twice
          expect(folio_response_json).to eq(updated_marc_json)
        end
      end

      context 'when source record does not show updated subfields at first' do
        let(:source_record_first_lookup) do
          { fields: [
            { '001': 'a666' },
            { '856': { ind1: '4',
                       ind2: '1',
                       subfields: [{ u: 'https://purl.stanford.edu/bc123dg9393' },
                                   { x: 'SDR-PURL' },
                                   { x: 'item' },
                                   { x: 'barcode:36105216275185' },
                                   { x: 'rights:stanford' }] } }
          ] }.deep_stringify_keys
        end

        before do
          allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record)
          allow(FolioClient).to receive(:fetch_marc_hash).and_return(source_record_first_lookup, source_record)
          allow(Rails.logger).to receive(:warn)
        end

        it 'updates the MARC record and retries lookups' do
          folio_writer.save
          expect(FolioClient).to have_received(:fetch_instance_info).twice
          expect(FolioClient).to have_received(:fetch_marc_hash).twice
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(Rails.logger).to have_received(:warn).once
          expect(folio_response_json).to eq(updated_marc_json)
        end
      end

      context 'when Folio operation raises more than max_lookup_tries times' do
        let(:instance_record) do
          {
            id: 'db80714e-398c-56f5-b228-7ad0874107cf',
            _version: '36',
            hrid: 'a10',
            electronicAccess: []
          }.deep_stringify_keys
        end

        before do
          allow(FolioClient).to receive_messages(fetch_instance_info: instance_record_unreleased, fetch_marc_hash: source_record)
          allow(Rails.logger).to receive(:warn)
        end

        it 'updates the MARC record and retries lookup until max_tries reached' do
          expect { folio_writer.save }.to raise_error(StandardError, 'FOLIO update not completed.')
          expect(FolioClient).to have_received(:fetch_instance_info).exactly(4).times
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:).once
          expect(Rails.logger).to have_received(:warn).exactly(4).times
          expect(Honeybadger).to have_received(:notify)
            .with(
              'Error updating Folio record',
              error_message: 'No matching PURL found in instance record after update.',
              context: { druid: }
            )
            .once
        end
      end

      context 'when there are two matching 856s on a source record after update' do
        let(:source_record_two_856s) do
          { fields: [
            { '001': 'a666' },
            { '856': { ind1: '4',
                       ind2: '1',
                       subfields: [{ u: 'https://purl.stanford.edu/bc123dg9393' },
                                   { x: 'SDR-PURL' },
                                   { x: 'item' },
                                   { x: 'barcode:36105216275185' },
                                   { x: 'rights:stanford' }] } },
            { '856': { ind1: '4',
                       ind2: '1',
                       subfields: [{ u: 'https://purl.stanford.edu/bc123dg9393' },
                                   { x: 'SDR-PURL' },
                                   { x: 'item' },
                                   { x: 'barcode:36105216275185' },
                                   { x: 'rights:stanford' }] } }
          ] }.deep_stringify_keys
        end

        before { allow(FolioClient).to receive(:fetch_marc_hash).and_return(source_record_two_856s) }

        it 'raises an error' do
          expect { folio_writer.save }.to raise_error(StandardError, 'FOLIO update not completed.')
          expect(Honeybadger).to have_received(:notify)
            .with(
              'Error updating Folio record',
              error_message: 'More than one matching field with a PURL found on FOLIO record.',
              context: { druid: }
            )
            .once
        end
      end
    end

    context 'when a single catalog record id that is unreleased' do
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

      context 'when unreleasing' do
        let(:release_data) { false }

        before { allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record_unreleased) }

        it 'updates the MARC record and does not add an 856' do
          folio_writer.save
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(folio_response_json).to eq(unreleased_marc_json)
        end
      end

      context 'when unrelease is not successful on a previously released druid' do
        let(:release_data) { false }

        before { allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record) }

        it 'raises an error' do
          expect { folio_writer.save }.to raise_error(StandardError, 'FOLIO update not completed.')
          expect(FolioClient).to have_received(:edit_marc_json).with(hrid:)
          expect(Honeybadger).to have_received(:notify)
            .with(
              'Error updating Folio record',
              error_message: 'PURL still found in instance record after update.',
              context: { druid: }
            )
            .once
        end
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

      before do
        allow(FolioClient).to receive(:fetch_instance_info).with(hrid: 'a8832160').and_return(instance_record_unreleased)
        allow(FolioClient).to receive(:fetch_instance_info).with(hrid: 'a8832162').and_return(instance_record)
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

      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record_unreleased)
      end

      it 'updates both MARC records to not include the 856' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832160')
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832161')
        expect(folio_response_json).to eq(unreleased_marc_json)
      end
    end

    context 'when previous catalog record id does not exist' do
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

      before do
        allow(FolioClient).to receive(:fetch_instance_info).and_return(instance_record_unreleased)
        allow(FolioClient).to receive(:edit_marc_json).with(hrid: 'a8832160').and_raise(FolioClient::ResourceNotFound)
        allow(FolioClient).to receive(:edit_marc_json).with(hrid: 'a8832161').and_yield(folio_response_json)
      end

      it 'updates MARC record that exists to not include the 856' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832160')
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: 'a8832161')
        expect(folio_response_json).to eq(unreleased_marc_json)
      end
    end

    context 'when releasing to SearchWorks multiple catalog records' do
      let(:hrid1) { 'a102345' }
      let(:hrid2) { 'a678901' }
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: hrid1
            },
            {
              catalog: 'folio',
              catalogRecordId: hrid2
            }
          ]
        }
      end

      it 'updates the MARC records' do
        folio_writer.save
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: hrid1)
        expect(FolioClient).to have_received(:edit_marc_json).with(hrid: hrid2)
      end
    end
  end
end
