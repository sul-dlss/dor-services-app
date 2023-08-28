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
          catalog: 'symphony',
          catalogRecordId: '123',
          refresh: true
        },
        {
          catalog: 'symphony',
          catalogRecordId: '456',
          refresh: false
        },
        {
          catalog: 'previous symphony',
          catalogRecordId: '012',
          refresh: false
        },
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
    instance_double(Catalog::MarcService, mods:, mods_ng: Nokogiri::XML(mods))
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

    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
          <titleInfo>
            <title>Paying for College</title>
          </titleInfo>
        </mods>
      XML
    end

    context 'when reading from Symphony' do
      before do
        allow(Settings.enabled_features).to receive(:read_folio).and_return(false)
      end

      it 'gets the data from Symphony and returns success' do
        expect(refresh.success?).to be(true)
        expect(refresh.value!.description_props).to eq({
                                                         title: [{ value: 'Paying for College' }],
                                                         purl: Purl.for(druid:)
                                                       })
        expect(refresh.value!.mods_ng_xml).to be_equivalent_to(Nokogiri::XML(mods))
        expect(Catalog::MarcService).to have_received(:new).with(catkey: '123')
        # expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context 'when reading from Folio' do
      it 'gets the data from Folio and returns success' do
        expect(refresh.success?).to be(true)
        expect(refresh.value!.description_props).to eq({
                                                         title: [{ value: 'Paying for College' }],
                                                         purl: Purl.for(druid:)
                                                       })
        expect(refresh.value!.mods_ng_xml).to be_equivalent_to(Nokogiri::XML(mods))
        expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a123')
      end
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

    context 'when barcode provided and configured to not use barcode' do
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

    context 'when no refreshable identifiers' do
      let(:identification) do
        {
          sourceId: 'sul:abc',
          catalogLinks: [
            {
              catalog: 'symphony',
              catalogRecordId: '456',
              refresh: false
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '012',
              refresh: false
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

    context 'when fetching metadata fails' do
      before do
        allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::CatalogResponseError)
      end

      it 'does not rescue the error' do
        expect { refresh }.to raise_error(Catalog::MarcService::CatalogResponseError)
      end
    end

    context 'when mods is nil' do
      before do
        allow(marc_service).to receive(:mods).and_return(nil)
      end

      it 'returns failure' do
        expect(refresh.failure?).to be(true)
      end
    end

    context 'when Descriptive.props returns nil' do
      before do
        allow(Cocina::Models::Mapping::FromMods::Description).to receive(:props).and_return(nil)
      end

      it 'returns failure' do
        expect(refresh.failure?).to be(true)
      end
    end
  end
end
