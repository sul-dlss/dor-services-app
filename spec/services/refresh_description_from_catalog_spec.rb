# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshDescriptionFromCatalog do
  include Dry::Monads[:result]

  let(:druid) { 'druid:bc753qt7345' }
  let(:description) do
    {
      title: [{ value: 'However am I going to be' }],
      purl: Purl.for(druid:)
    }
  end
  let(:identification) do
    {
      sourceId: 'sul:abc',
      catalogLinks: [
        {
          catalog: 'folio',
          catalogRecordId: 'a123',
          refresh: true
        },
        {
          catalog: 'folio',
          catalogRecordId: 'a456',
          refresh: false
        },
        {
          catalog: 'previous folio',
          catalogRecordId: 'a012',
          refresh: false
        }
      ]
    }
  end

  let(:marc_service) do
    instance_double(Catalog::MarcService)
  end

  before do
    allow(Catalog::MarcService).to receive(:new).and_return(marc_service)
  end

  describe '#refresh' do
    subject(:refresh) { described_class.run(cocina_object:, druid:, use_barcode:) }

    let(:use_barcode) { false }
    let(:apo_druid) { 'druid:pp000pp0000' }
    let(:cocina_object) do
      build(:dro, id: druid).new(description:, identification:)
    end
    let(:marc) do
      { fields: [
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
    let(:marc_service) do
      instance_double(Catalog::MarcService, marc:)
    end

    context 'when barcode provided and configured to use barcode' do
      let(:use_barcode) { true }
      let(:identification) do
        {
          sourceId: 'sul:abc',
          barcode: '36105123456789',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: 'a123',
              refresh: true
            }
          ]
        }
      end

      it 'gets the data from Folio by barcode and returns success' do
        expect(refresh.success?).to be(true)
        expect(Catalog::MarcService).to have_received(:new).with(barcode: '36105123456789', folio_instance_hrid: 'a123')
      end
    end

    context 'when barcode provided but using barcode default of false' do
      let(:identification) do
        {
          sourceId: 'sul:abc',
          barcode: '36105123456789',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: 'a123',
              refresh: true
            }
          ]
        }
      end

      it 'gets the data from Folio without barcode and returns success' do
        expect(refresh.success?).to be(true)
        expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a123')
      end
    end

    context 'when barcode provided and configured but folio refresh is set to false' do
      let(:use_barcode) { true }
      let(:identification) do
        {
          sourceId: 'sul:abc',
          barcode: '36105123456789',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: 'a123',
              refresh: false
            }
          ]
        }
      end

      it 'returns failure' do
        expect(refresh.failure?).to be(true)
        expect(Catalog::MarcService).not_to have_received(:new)
      end
    end

    context 'when refreshing with a valid catalog link' do
      let(:identification) do
        {
          sourceId: 'sul:abc',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: 'a123',
              refresh: true
            }
          ]
        }
      end
      let(:today) { Time.zone.now.strftime('%Y-%m-%d') }

      it 'gets the data from Folio and returns success' do
        expect(refresh.success?).to be(true)
        expect(refresh.value!.description_props).to eq({
                                                         title: [{ value: 'Gaudy night' }],
                                                         purl: Purl.for(druid:),
                                                         note: [
                                                           {
                                                             value: 'by Dorothy L. Sayers.',
                                                             type: 'statement of responsibility'
                                                           }
                                                         ],
                                                         adminMetadata: {
                                                           note: [
                                                             {
                                                               value: "Converted from MARC to Cocina #{today}",
                                                               type: 'record origin'
                                                             }
                                                           ]
                                                         }
                                                       })
        expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a123')
      end
    end

    context 'when no refreshable identifiers' do
      let(:identification) do
        {
          sourceId: 'sul:abc',
          catalogLinks: [
            {
              catalog: 'folio',
              catalogRecordId: 'a456',
              refresh: false
            },
            {
              catalog: 'previous folio',
              catalogRecordId: 'a012',
              refresh: false
            }
          ]
        }
      end

      it 'returns failure' do
        expect(refresh.failure?).to be(true)
      end
    end

    context 'when admin policy' do
      let(:cocina_object) { build(:admin_policy) }

      it 'returns failure' do
        expect(refresh.failure?).to be(true)
      end
    end
  end
end
