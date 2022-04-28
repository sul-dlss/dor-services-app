# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::DescriptionRoundtripValidator do
  describe '.valid_from_cocina?' do
    let(:result) { described_class.valid_from_cocina?(cocina_object) }

    let(:cocina_hash) do
      {
        type: Cocina::Models::ObjectType.book,
        label: 'Born to Run',
        version: 1,
        access: {
          view: 'world',
          download: 'none'
        },
        description: {
          title: [{ value: 'Born to Run' }],
          purl: 'https://purl.stanford.edu/ff111df4567'
        },
        administrative: {
          hasAdminPolicy: 'druid:dd999df4567'
        },
        identification: { sourceId: 'googlebooks:999999' },
        externalIdentifier: 'druid:ff111df4567',
        structural: {}
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
        changed_cocina_hash = cocina_hash[:description].merge(contributor: [{ name: [{ value: 'Stanford University. Department of Geophysics' }] }])
        allow(Cocina::Models::Mapping::FromMods::Description).to receive(:props).and_return(changed_cocina_hash)
      end

      it 'returns failure' do
        expect(result.failure?).to be true
      end
    end

    context 'with request' do
      let(:request_cocina_hash) do
        {
          type: Cocina::Models::ObjectType.book,
          label: 'Born to Run',
          version: 1,
          access: {
            view: 'world',
            download: 'none'
          },
          description: {
            title: [{ value: 'Born to Run' }]
          },
          administrative: {
            hasAdminPolicy: 'druid:dd999df4567'
          },
          identification: { sourceId: 'googlebooks:999999' }
        }
      end

      let(:cocina_object) do
        Cocina::Models::RequestDRO.new(request_cocina_hash)
      end

      it 'returns success' do
        expect(result.success?).to be true
      end
    end

    context 'when purl in relatedResource' do
      let(:related_resource) do
        [
          {
            title: [
              {
                value: 'Software Carpentry Workshop recordings from August 14, 2014'
              }
            ],
            purl: 'https://purl.stanford.edu/tx853fp2857'
          }
        ]
      end
      let(:cocina_object) do
        new_cocina_hash = cocina_hash.dup
        new_cocina_hash[:description][:relatedResource] = related_resource
        Cocina::Models::DRO.new(new_cocina_hash)
      end

      it 'returns success' do
        expect(result.success?).to be true
      end
    end

    context 'when has an identifier type that does not roundtrip' do
      let(:cocina_object) do
        new_cocina_hash = cocina_hash.dup
        new_cocina_hash[:description][:identifier] = [{
          value: 'GM 132. Amadeus.',
          type: 'music publisher'
        }]
        Cocina::Models::DRO.new(new_cocina_hash)
      end

      it 'returns success (ignoring identifier)' do
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
        allow(Cocina::Models::Mapping::Normalizers::ModsNormalizer).to receive(:normalize).and_return(Nokogiri::XML(mods.gsub('Chi Running', 'Zen of Running')))
      end

      it 'returns failure' do
        expect(result.failure?).to be true
      end
    end

    context 'when purl in related item' do
      let(:mods) do
        <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
            <titleInfo>
              <title>Chi Running</title>
            </titleInfo>
            <relatedItem>
              <location>
                <url>http://purl.stanford.edu/zz599zz9959</url>
              </location>
            </relatedItem>
            <relatedItem>
              <location>
                <url usage="primary display">http://purl.stanford.edu/ng599nr9959</url>
              </location>
            </relatedItem>
          </mods>
        XML
      end

      it 'returns success' do
        expect(result.success?).to be true
      end
    end
  end
end
