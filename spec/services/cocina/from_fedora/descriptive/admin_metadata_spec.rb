# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::AdminMetadata do
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

  context 'with recordInfo from a replayable spreadsheet' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
            <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
          </languageOfCataloging>
          <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          <descriptionStandard authority="dacs" authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs"></descriptionStandard>
          <recordOrigin>human prepared</recordOrigin>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "language": [
          {
            "value": 'English',
            "code": 'eng',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
            "source": {
              "code": 'iso639-2b',
              "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
            },
            "script": {
              "value": 'Latin',
              "code": 'Latn',
              "source": {
                "code": 'iso15924'
              }
            }
          }
        ],
        "contributor": [
          {
            "name": [
              {
                "code": 'CSt',
                "uri": 'http://id.loc.gov/vocabulary/organizations/cst',
                "source": {
                  "code": 'marcorg',
                  "uri": 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            "type": 'organization',
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          }
        ],
        "standard": {
          "code": 'dacs',
          "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
          "source": {
            "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/'
          }
        },
        "note": [
          {
            "type": 'record origin',
            "value": 'human prepared'
          }
        ]
      )
    end
  end

  context 'with multiple languages' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_recordInfo.txt#L70'
  end

  context 'with recordInfo converted from MARC' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_recordInfo.txt#L146'
  end

  context 'with recordInfo converted from ISO 19139' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_recordInfo.txt#L213'
  end
end
