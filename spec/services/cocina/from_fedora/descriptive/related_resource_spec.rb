# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::RelatedResource do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with empty location (from Hydrus)' do
    let(:xml) do
      <<~XML
        <relatedItem>
          <titleInfo>
            <title/>
          </titleInfo>
          <location>

          </location>
        </relatedItem>
      XML
    end

    it 'builds nothing' do
      expect(build).to be_empty
    end
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

    context 'when type is mis-capitalized isReferencedBy' do
      let(:xml) do
        <<~XML
          <relatedItem displayLabel="Original James Record" type="isReferencedby">
            <titleInfo>
              <title>https://stacks.stanford.edu/file/druid:mf281cz1275/MS_296.pdf</title>
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
            'displayLabel': 'Original James Record',
            'title': [
              {
                'value': 'https://stacks.stanford.edu/file/druid:mf281cz1275/MS_296.pdf'
              }
            ],
            'type': 'referenced by'
          }
        ]
        expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Invalid related resource type (isReferencedby)', { tags: 'data_error' })
      end
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

  context 'with a totally unknown relatedItem type' do
    let(:xml) do
      <<~XML
        <relatedItem type="Really bogus">
          <titleInfo>
            <title>Lymond chronicles</title>
          </titleInfo>
        </relatedItem>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'leaves off the type and notifies honeybadger' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Lymond chronicles'
            }
          ]
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Invalid related resource type (Really bogus)', { tags: 'data_error' })
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

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "title": [
            {
              "value": 'Supplement'
            }
          ],
          "note": [
            {
              "value": 'Additional data.',
              "type": 'summary'
            }
          ]
        }
      ]
    end
  end

  context 'without title' do
    let(:xml) do
      <<~XML
        <relatedItem>
          <abstract>Additional data.</abstract>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "note": [
            {
              "value": 'Additional data.',
              "type": 'summary'
            }
          ]
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

  context 'with type and otherType (invalid)' do
    let(:xml) do
      <<~XML
        <relatedItem type="otherFormat" otherType="Online version:" displayLabel="Online version:">
          <titleInfo>
            <title>Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften.</title>
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
              "value": 'Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften.'
            }
          ],
          "type": 'has other format',
          "displayLabel": 'Online version:'
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Related resource has type and otherType', { tags: 'data_error' })
    end
  end

  context 'with otherType' do
    let(:xml) do
      <<~XML
        <relatedItem otherType="has part" otherTypeURI="http://purl.org/dc/terms/hasPart" otherTypeAuth="DCMI">
          <titleInfo>
            <title>A related resource</title>
          </titleInfo>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'related to',
          "title": [
            {
              "value": 'A related resource'
            }
          ],
          "note": [
            {
              "type": 'other relation type',
              "value": 'has part',
              "uri": 'http://purl.org/dc/terms/hasPart',
              "source": {
                "value": 'DCMI'
              }
            }
          ]
        }
      ]
    end
  end
end
