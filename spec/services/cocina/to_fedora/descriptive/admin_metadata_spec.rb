# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::AdminMetadata do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, admin_metadata: admin_metadata)
      end
    end
  end

  context 'when admin_metadata is nil' do
    let(:admin_metadata) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it is from replayable spreadsheet (with desc standard value)' do
    let(:admin_metadata) do
      Cocina::Models::DescriptiveAdminMetadata.new(
        language: [
          {
            value: 'English',
            code: 'eng',
            uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
            source: {
              code: 'iso639-2b',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/'
            },
            script: {
              value: 'Latin',
              code: 'Latn',
              source: {
                code: 'iso15924'
              }
            },
            status: 'primary'
          }
        ],
        contributor: [
          {
            name: [
              {
                code: 'CSt',
                uri: 'http://id.loc.gov/vocabulary/organizations/cst',
                source: {
                  code: 'marcorg',
                  uri: 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'original cataloging agency'
              }
            ]
          }
        ],
        metadataStandard: [
          {
            uri: 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
            value: "Describing archives: a content standard\u00A0(Chicago: Society of American Archivists)",
            source: {
              uri: 'http://id.loc.gov/vocabulary/descriptionConventions/'
            }
          }
        ],
        note: [
          {
            type: 'record origin',
            value: 'human prepared'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <recordInfo>
            <languageOfCataloging usage="primary">
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
              <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
              <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
              <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
            </languageOfCataloging>
            <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
            <descriptionStandard authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs">Describing archives: a content standard&#xA0;(Chicago: Society of American Archivists)</descriptionStandard>
            <recordOrigin>human prepared</recordOrigin>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when there is no "note" (e.g. jv711gt9148)' do
    let(:admin_metadata) do
      Cocina::Models::DescriptiveAdminMetadata.new(
        {
          contributor: [
            {
              name: [
                {
                  code: 'DOR_MARC2MODS3-3.xsl Revision 1.1',
                  source: {}
                }
              ],
              role: [
                {
                  value: 'original cataloging agency'
                }
              ],
              type: 'organization'
            }
          ],
          event: [
            {
              date: [
                {
                  encoding: {
                    code: 'iso8601'
                  },
                  value: '2011-02-08T20:00:27.321-08:00'
                }
              ],
              type: 'creation'
            }
          ],
          identifier: [
            {
              type: 'Data Provider Digital Object Identifier',
              value: '36105033329140'
            }
          ]
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <recordInfo>
            <recordContentSource>DOR_MARC2MODS3-3.xsl Revision 1.1</recordContentSource>
            <recordCreationDate encoding="iso8601">2011-02-08T20:00:27.321-08:00</recordCreationDate>
            <recordIdentifier source="Data Provider Digital Object Identifier">36105033329140</recordIdentifier>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when identifier is missing source' do
    let(:admin_metadata) do
      Cocina::Models::DescriptiveAdminMetadata.new(
        {
          identifier: [
            {
              value: '36105033329140'
            }
          ]
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <recordInfo>
            <recordIdentifier>36105033329140</recordIdentifier>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when event is missing date' do
    let(:admin_metadata) do
      Cocina::Models::DescriptiveAdminMetadata.new(
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2011-09-27T12:58:15.677+02:00'
                }
              ]
            }
          ]
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <recordInfo>
            <recordCreationDate>2011-09-27T12:58:15.677+02:00</recordCreationDate>
          </recordInfo>
        </mods>
      XML
    end
  end
end
