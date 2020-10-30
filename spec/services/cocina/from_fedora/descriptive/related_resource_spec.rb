# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::RelatedResource do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with type' do
    let(:xml) do
      <<~XML
        <relatedItem type="series">
          <titleInfo>
            <title>Lymond chronicles</title>
          </titleInfo>
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <physicalDescription>
            <extent>6 vols.</extent>
          </physicalDescription>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Lymond chronicles'
            }
          ],
          "contributor": [
            {
              "type": 'person',
              "name": [
                {
                  "value": 'Dunnett, Dorothy'
                }
              ]
            }
          ],
          "form": [
            {
              "value": '6 vols.',
              "type": 'extent'
            }
          ],
          "type": 'in series'
        }
      ]
    end
  end

  context 'with Other version type data error' do
    let(:xml) do
      <<~XML
        <relatedItem type="Other version">
          <titleInfo>
            <title>Lymond chronicles</title>
          </titleInfo>
        </relatedItem>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Lymond chronicles'
            }
          ],
          "type": 'has version'
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Invalid related resource type (Other version)', { tags: 'data_error' })
    end
  end

  context 'without type' do
    let(:xml) do
      <<~XML
        <relatedItem>
          <titleInfo>
            <title>Supplement</title>
          </titleInfo>
          <abstract>Additional data.</abstract>
        </relatedItem>
      XML
    end

    xit 'TODO: Justin is in discussion with Arcadia about how this should look.'
    # https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_relatedItem.txt#L52-L66
    # appears to be incorrect
  end

  context 'without title' do
    let(:xml) do
      <<~XML
        <relatedItem>
          <location>
            <url>https://www.example.com</url>
          </location>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "access": {
            "url": [
              {
                "value": 'https://www.example.com'
              }
            ]
          }
        }
      ]
    end
  end

  context 'with multiple related items' do
    let(:xml) do
      <<~XML
        <relatedItem>
          <titleInfo>
            <title>Related item 1</title>
          </titleInfo>
        </relatedItem>
        <relatedItem>
          <titleInfo>
            <title>Related item 2</title>
          </titleInfo>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Related item 1'
            }
          ]
        },
        {
          "title": [
            {
              "value": 'Related item 2'
            }
          ]
        }
      ]
    end
  end

  context 'with a displayLabel' do
    let(:xml) do
      <<~XML
        <relatedItem displayLabel="Additional data">
          <titleInfo>
            <title>Supplement</title>
          </titleInfo>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Supplement'
            }
          ],
          "displayLabel": 'Additional data'
        }
      ]
    end
  end
end
