# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::DescriptionRoundtripValidator do
  describe '.valid_from_cocina?' do
    let(:result) { described_class.valid_from_cocina?(cocina_object) }

    let(:cocina_hash) do
      {
        type: Cocina::Models::Vocab.book,
        label: 'Born to Run',
        version: 1,
        access: {
          access: 'world',
          download: 'none'
        },
        description: {
          title: [{ value: 'Born to Run' }],
          purl: 'http://purl.stanford.edu/ff111df4567',
          access: {
            digitalRepository: [
              { value: 'Stanford Digital Repository' }
            ]
          }
        },
        administrative: {
          hasAdminPolicy: 'druid:dd999df4567'
        },
        identification: { sourceId: 'googlebooks:999999' },
        externalIdentifier: 'druid:ff111df4567'
      }
    end

    let(:cocina_object) { Cocina::Models::DRO.new(cocina_hash) }

    context 'when valid' do
      it 'returns success' do
        expect(result.success?).to be true
      end
    end

    context 'when has empty values' do
      let(:cocina_object) do
        new_cocina_hash = cocina_hash.dup
        new_cocina_hash[:description][:relatedResource] = []
        Cocina::Models::DRO.new(new_cocina_hash)
      end

      it 'ignores and returns success' do
        expect(result.success?).to be true
      end
    end

    context 'when invalid' do
      before do
        changed_cocina_hash = cocina_hash[:description].except(:purl)
        allow(Cocina::FromFedora::Descriptive).to receive(:props).and_return(changed_cocina_hash)
      end

      it 'returns failure' do
        expect(result.failure?).to be true
      end
    end

    context 'with request' do
      let(:cocina_object) { Cocina::Models::RequestDRO.new(cocina_hash.except(:externalIdentifier)) }

      it 'returns success' do
        expect(result.success?).to be true
      end
    end
  end

  describe '.valid_from_fedora?' do
    let(:result) { described_class.valid_from_fedora?(fedora_object) }

    let(:fedora_object) do
      Dor::Item.new(
        pid: 'druid:ff111df4567',
        label: 'Chi Running'
      ).tap do |item|
        item.descMetadata.content = mods
      end
    end

    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
          <titleInfo>
            <title>Chi Running</title>
          </titleInfo>
        </mods>
      XML
    end

    context 'when valid' do
      it 'returns success' do
        expect(result.success?).to be true
      end
    end

    context 'when invalid' do
      before do
        allow(Cocina::Normalizers::ModsNormalizer).to receive(:normalize).and_return(Nokogiri::XML(mods.gsub('Chi Running', 'Zen of Running')))
      end

      it 'returns failure' do
        expect(result.failure?).to be true
      end
    end
  end
end
