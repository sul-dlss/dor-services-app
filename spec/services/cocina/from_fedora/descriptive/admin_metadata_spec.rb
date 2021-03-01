# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::AdminMetadata do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a descriptionStandard that has a value' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </languageOfCataloging>
          <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          <descriptionStandard authority="dacs" authorityURI="http://id.loc.gov/vocabulary/descriptionConventions" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs">Describing archives: a content standard&#xA0;(Chicago: Society of American Archivists)</descriptionStandard>
          <recordOrigin>human prepared</recordOrigin>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        language: [
          {
            code: 'eng',
            value: 'English',
            uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
            source: {
              code: 'iso639-2b',
              uri: 'http://id.loc.gov/vocabulary/iso639-2'
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
                  uri: 'http://id.loc.gov/vocabulary/organizations'
                }
              }
            ],
            type: 'organization',
            role: [
              { value: 'original cataloging agency' }
            ]
          }
        ],
        metadataStandard: [
          {
            uri: 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
            value: "Describing archives: a content standard\u00A0(Chicago: Society of American Archivists)",
            source: {
              uri: 'http://id.loc.gov/vocabulary/descriptionConventions/',
              code: 'dacs'
            }
          }
        ],
        note: [
          { type: 'record origin', value: 'human prepared' }
        ]
      )
    end
  end

  context 'when languageOfCataloging has an capitalized (invalid) usage' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="Primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq(
        language: [
          {
            value: 'English',
            status: 'primary',
            code: 'eng',
            uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
            source: {
              code: 'iso639-2b',
              uri: 'http://id.loc.gov/vocabulary/iso639-2'
            }
          }
        ]
      )
      expect(notifier).to have_received(:warn).with(
        'languageOfCataloging usage attribute not downcased', { value: 'Primary' }
      )
    end
  end

  context 'with no authority listed for scriptTerm code' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
            <scriptTerm type="text">Latin</scriptTerm>
            <scriptTerm type="code">Latn</scriptTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure and does not add a scriptTerm source instead of setting to nil' do
      expect(build).to eq(
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
              code: 'Latn'
            }
          }
        ]
      )
    end
  end

  context 'with recordIdentifier missing source' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordIdentifier>a12374669</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        identifier: [
          {
            value: 'a12374669'
          }
        ]
      )
    end
  end

  context 'when there is no recordOrigin element (e.g. jv711gt9148)' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordContentSource>DOR_MARC2MODS3-3.xsl Revision 1.1</recordContentSource>
          <recordCreationDate encoding="iso8601">2011-02-08T20:00:27.321-08:00</recordCreationDate>
          <recordIdentifier source="Data Provider Digital Object Identifier">36105033329140</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          contributor: [
            {
              name: [
                {
                  value: 'DOR_MARC2MODS3-3.xsl Revision 1.1'
                }
              ]
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
  end

  context 'when there are multiple recordIdentifiers' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordIdentifier source="SUL catalog key">6766105</recordIdentifier>
          <recordIdentifier source="oclc">3888071</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          identifier: [
            {
              type: 'SUL catalog key',
              value: '6766105'
            },
            {
              type: 'OCLC',
              value: '3888071'
            }
          ]
        }
      )
    end
  end

  context 'when there is no encoding for the recordCreationDate' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordCreationDate>2011-02-08T20:00:27.321-08:00</recordCreationDate>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure leaving the code off instead of setting to nil' do
      expect(build).to eq(
        {
          event: [
            {
              date: [
                {
                  value: '2011-02-08T20:00:27.321-08:00'
                }
              ],
              type: 'creation'
            }
          ]
        }
      )
    end
  end

  context 'with languageTerm missing type' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging>
            <languageTerm authority="iso639-2b">eng</languageTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq(
        language: [
          {
            code: 'eng',
            source: {
              code: 'iso639-2b'
            }
          }
        ]
      )
      expect(notifier).to have_received(:warn).with('languageTerm missing type')
    end
  end
end
