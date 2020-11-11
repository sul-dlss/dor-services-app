# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::RelatedResource do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, related_resources: resources)
      end
    end
  end

  context 'when relatedResource is nil' do
    let(:resources) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it has a related item with type' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        </mods>
      XML
    end
  end

  context 'when it has a related item without type' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem>
            <titleInfo>
              <title>Supplement</title>
            </titleInfo>
            <abstract>Additional data.</abstract>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when it has a related item with the generic "related to" type (related link from H2)' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "title": [
            {
              "value": 'Supplement'
            }
          ],
          "access": {
            "url": [
              "value": 'https://example.com/paper.html'
            ]
          },
          "type": 'related to'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem>
            <titleInfo>
              <title>Supplement</title>
            </titleInfo>
            <location>
              <url>https://example.com/paper.html</url>
            </location>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when it has a related item with the generic "related to" type (related work from H2)' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "note": [
            {
              "value": 'Stanford University (Stanford, CA.). (2020)',
              "type": 'preferred citation'
            }
          ],
          "type": 'related to'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem>
            <note type="preferred citation">Stanford University (Stanford, CA.). (2020)</note>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when it has a related item without title' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "access": {
            "url": [
              {
                "value": 'https://www.example.com'
              }
            ]
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem>
            <location>
              <url>https://www.example.com</url>
            </location>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when it has multiple related items' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "title": [
            {
              "value": 'Related item 1'
            }
          ]
        ),
        Cocina::Models::RelatedResource.new(
          "title": [
            {
              "value": 'Related item 2'
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        </mods>
      XML
    end
  end

  context 'when it has displayLabel' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "title": [
            {
              "value": 'Fremontia : Journal of the California Native Plant Society'
            }
          ],
          "displayLabel": 'Contained in (manifestation):'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem displayLabel="Contained in (manifestation):">
            <titleInfo>
              <title>Fremontia : Journal of the California Native Plant Society</title>
            </titleInfo>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when it has a related item with a contributor without a type' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          {
            "title": [
              {
                "value": 'Lymond chronicles'
              }
            ],
            "contributor": [
              {
                "name": [
                  {
                    "value": 'Dunnett, Dorothy'
                  }
                ]
              }
            ]
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <relatedItem>
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
            </name>
          </relatedItem>
        </mods>
      XML
    end
  end
end
