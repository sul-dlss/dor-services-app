# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, subjects: subjects, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when it has a organization subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            value: 'Stanford University',
            type: 'organization',
            uri: 'http://id.loc.gov/authorities/names/n79054636',
            source: {
              code: 'naf',
              uri: 'http://id.loc.gov/authorities/names/'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79054636">
              <namePart>Stanford University</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with authority only' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
            type: 'person',
            source: {
              code: 'naf'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <name authority="naf" type="personal">
              <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the name' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                value: 'Shakespeare, William, 1564-1616',
                type: 'person',
                uri: 'http://id.loc.gov/authorities/names/n78095332',
                source: {
                  code: 'naf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                value: 'Homes and haunts',
                type: 'topic'
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
          <subject>
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                value: 'Shakespeare, William, 1564-1616',
                type: 'person',
                uri: 'http://id.loc.gov/authorities/names/n78095332',
                source: {
                  code: 'naf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                value: 'Homes and haunts',
                type: 'topic',
                uri: 'http://id.loc.gov/authorities/subjects/sh99005711',
                source: {
                  code: 'lcsh',
                  uri: 'http://id.loc.gov/authorities/subjects/'
                }
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
          <subject authority="lcsh">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for terms and set' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                value: 'Shakespeare, William, 1564-1616',
                type: 'person',
                uri: 'http://id.loc.gov/authorities/names/n78095332',
                source: {
                  code: 'naf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                value: 'Homes and haunts',
                type: 'topic',
                uri: 'http://id.loc.gov/authorities/subjects/sh99005711',
                source: {
                  code: 'lcsh',
                  uri: 'http://id.loc.gov/authorities/subjects/'
                }
              }
            ],
            uri: 'http://id.loc.gov/authorities/subjects/sh85120951',
            source: {
              code: 'lcsh',
              uri: 'http://id.loc.gov/authorities/subjects/'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  # From druid:mt538yc4849
  context 'with a name-title subject where title has partNumber' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          source: {
            code: 'lcsh'
          },
          structuredValue: [
            {
              structuredValue: [
                {
                  value: 'California.',
                  type: 'name'
                },
                {
                  value: 'Sect. 7570.',
                  type: 'name'
                }
              ],
              type: 'organization'
            },
            {
              structuredValue: [
                {
                  value: 'Government Code',
                  type: 'main title'
                },
                {
                  value: 'Sect. 7570',
                  type: 'part number'
                }
              ],
              type: 'title'
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
          <subject authority="lcsh">
            <name type="corporate">
              <namePart>California.</namePart>
              <namePart>Sect. 7570.</namePart>
            </name>
            <titleInfo>
              <title>Government Code</title>
              <partNumber>Sect. 7570</partNumber>
            </titleInfo>
          </subject>
        </mods>
      XML
    end
  end
end
