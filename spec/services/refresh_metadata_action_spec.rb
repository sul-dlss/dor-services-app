# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshMetadataAction do
  include Dry::Monads[:result]
  let(:druid) { 'druid:bc753qt7345' }
  let(:description) do
    {
      title: [{ value: 'However am I going to be' }],
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end

  describe '#refresh' do
    subject(:refresh) { described_class.run(identifiers: ['catkey:123'], cocina_object: cocina_object, druid: druid) }

    let(:apo_druid) { 'druid:pp000pp0000' }
    let(:cocina_object) do
      build(:dro, id: druid).new(description: description)
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

    before do
      allow(ModsService).to receive(:fetch).and_return(mods)
      allow(Honeybadger).to receive(:notify)
    end

    it 'gets the data and returns success' do
      expect(refresh.success?).to be(true)
      expect(refresh.value!.description_props).to eq({
                                                       title: [{ value: 'Paying for College' }],
                                                       purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
                                                     })
      expect(refresh.value!.mods_ng_xml).to be_equivalent_to(Nokogiri::XML(mods))
      expect(Honeybadger).not_to have_received(:notify)
    end

    context 'when fetch_metadata fails' do
      before do
        allow(ModsService).to receive(:fetch).and_raise(SymphonyReader::ResponseError)
      end

      it 'gets the data and puts it in descMetadata and Honeybadger notifies' do
        expect { refresh }.to raise_error(SymphonyReader::ResponseError)
      end
    end

    context 'when fetch_metadata returns nil' do
      before do
        allow(ModsService).to receive(:fetch).and_return(nil)
      end

      it 'returns a Dry::Monads::Result::Failure object' do
        expect(refresh.failure?).to be(true)
      end
    end

    context 'when Descriptive.props returns nil' do
      before do
        allow(Cocina::Models::Mapping::FromMods::Description).to receive(:props).and_return(nil)
      end

      it 'returns a Dry::Monads::Result::Failure object' do
        expect(refresh.failure?).to be(true)
      end
    end
  end

  describe '#identifiers' do
    subject(:indentifiers) { described_class.identifiers(cocina_object: cocina_object) }

    let(:identification) { instance_double(Cocina::Models::RequestIdentification, catalogLinks: catalog_links) }
    let(:cocina_object) do
      instance_double(Cocina::Models::RequestDRO, admin_policy?: false, identification: identification, to_h: {}, dro?: true, collection?: false)
    end

    context 'when a valid identifier' do
      let(:catalog_links) do
        [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'nope123', refresh: false),
         Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'yup123', refresh: true),
         Cocina::Models::CatalogLink.new(catalog: 'previous symphony', catalogRecordId: 'old123', refresh: true)]
      end

      it 'returns only the valid symphony identifier with refresh == true' do
        expect(indentifiers).to eq(['catkey:yup123'])
      end
    end

    context 'when no identifiers' do
      let(:catalog_links) { [] }

      it 'returns an empty array' do
        expect(indentifiers).to eq([])
      end
    end

    context 'when no valid identifiers' do
      let(:catalog_links) do
        [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'nope123', refresh: false)]
      end

      it 'returns an empty array' do
        expect(indentifiers).to eq([])
      end
    end
  end
end
