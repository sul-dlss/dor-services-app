# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::HoldingsGenerator do
  subject(:holdings_generator) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:dro).new(identification: identification) }
  let(:sdr_location_id) { 'abcd-0000' }
  let(:sdr_locations) do
    { sul_sdr: { id: 'abcd-0000', campus_id: '1234' },
      business_sdr: { id: 'efgh-1111', campus_id: '5678' } }
  end

  let(:existing_holdings) do
    [
      { 'id' => '123', 'instance_id' => '1234-5678-0000', 'permanentLocationId' => sdr_location_id,
        'discoverySuppress' => true },
      { 'id' => '456', 'instance_id' => '2222-2222-2222', 'permanentLocationId' => 'xxxx-xxxx-xxxx',
        'discoverySuppress' => false }
    ]
  end
  let(:hrid) { 'a1234' }
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

  before do
    allow(FolioClient).to receive(:fetch_holdings).and_return(existing_holdings)
    allow(Honeybadger).to receive(:notify)
    allow(Settings.catalog.folio).to receive(:sdr_locations).and_return(sdr_locations)
    allow(PublicMetadataReleaseTagService).to receive(:released_to_searchworks?).and_return(true)
  end

  describe '#manage_holdings' do
    context 'when the object is released to SearchWorks' do
      before do
        allow(FolioClient).to receive(:fetch_location)
          .with(location_id: sdr_location_id).and_return({
                                                           'id' => sdr_location_id, 'campusId' => '1234'
                                                         })
        allow(FolioClient).to receive_messages(update_holdings: true, fetch_external_id: '1234-5678-0000')
      end

      context 'when there is an existing SDR holding' do
        it 'updates the existing SDR holding' do
          described_class.manage_holdings(cocina_object)

          expect(FolioClient).to have_received(:update_holdings)
            .with(holdings_id: '123',
                  holdings_record: { 'id' => '123',
                                     'instance_id' => '1234-5678-0000',
                                     'permanentLocationId' => sdr_location_id,
                                     'discoverySuppress' => false })
        end
      end

      context 'when there are multiple existing SDR holdings' do
        let(:existing_holdings) do
          [
            { 'id' => '123', 'instance_id' => '1234-5678-0000', 'permanentLocationId' => sdr_location_id,
              'discoverySuppress' => true },
            { 'id' => '456', 'instance_id' => '1234-5678-0001', 'permanentLocationId' => sdr_location_id,
              'discoverySuppress' => true }
          ]
        end

        it 'raises if there are multiple holdings for SDR locations' do
          expect { described_class.manage_holdings(cocina_object) }.to raise_error(StandardError)
        end
      end

      context 'when there are no existing SDR holdings' do
        let(:existing_holdings) do
          [
            { 'id' => '123', 'instance_id' => '1234-5678-0000', 'permanentLocationId' => '5555-5555-5555',
              'discoverySuppress' => true }
          ]
        end

        before do
          allow(FolioClient).to receive(:create_holdings)
          allow(FolioClient).to receive_messages(fetch_holdings: existing_holdings, fetch_external_id: '1234-5678-0000')
          allow(FolioClient).to receive(:fetch_location)
            .with(location_id: '5555-5555-5555').and_return({
                                                              'id' => '456', 'campusId' => '5678'
                                                            })
        end

        it 'creates a new holdings record for the matching campus' do
          described_class.manage_holdings(cocina_object)

          expect(FolioClient).to have_received(:create_holdings).with(
            holdings_record: hash_including(
              'instance_id' => '1234-5678-0000',
              'permanent_location_id' => 'efgh-1111',
              'source_id' => 'f32d531e-df79-46b3-8932-cdd35f7a2264',
              'holdings_type_id' => '996f93e2-5b5e-4cf2-9168-33ced1f95eed',
              'discoverySuppress' => false
            )
          )
        end
      end

      context 'when there are no holdings for a matching campus' do
        let(:existing_holdings) do
          [
            { 'id' => '123', 'instance_id' => '1234-5678-0000', 'permanentLocationId' => '5555-5555-5555',
              'discoverySuppress' => true }
          ]
        end

        before do
          allow(FolioClient).to receive(:create_holdings)
          allow(FolioClient).to receive_messages(fetch_holdings: existing_holdings,
                                                 fetch_external_id: '1234-5678-0000')
          allow(FolioClient).to receive(:fetch_location)
            .with(location_id: '5555-5555-5555').and_return({
                                                              'id' => '456', 'campusId' => '9999'
                                                            })
        end

        it 'creates a new holdings record for SUL SDR' do
          described_class.manage_holdings(cocina_object)

          expect(FolioClient).to have_received(:create_holdings).with(
            holdings_record: hash_including(
              'instance_id' => '1234-5678-0000',
              'permanent_location_id' => 'abcd-0000',
              'source_id' => 'f32d531e-df79-46b3-8932-cdd35f7a2264',
              'holdings_type_id' => '996f93e2-5b5e-4cf2-9168-33ced1f95eed',
              'discoverySuppress' => false
            )
          )
        end
      end
    end

    context 'when the object is not released to SearchWorks' do
      let(:existing_holdings) do
        [
          { 'id' => '123', 'instance_id' => '1234-5678-0000', 'permanentLocationId' => sdr_location_id,
            'discoverySuppress' => false },
          { 'id' => '456', 'instance_id' => '2222-2222-2222', 'permanentLocationId' => 'xxxx-xxxx-xxxx',
            'discoverySuppress' => false }
        ]
      end

      before do
        allow(PublicMetadataReleaseTagService).to receive(:released_to_searchworks?).and_return(false)
        allow(FolioClient).to receive(:update_holdings).and_return(true)
      end

      it 'changes discoverySuppress on an existing SDR holding' do
        described_class.manage_holdings(cocina_object)
        expect(FolioClient).to have_received(:update_holdings)
          .with(holdings_id: '123',
                holdings_record: hash_including('discoverySuppress' => true))
      end
    end
  end
end
