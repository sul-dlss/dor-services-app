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

  context 'when it has a geographic subject subdivision' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Europe',
              "type": 'place'
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
          <subject>
            <topic>Cats</topic>
            <geographic>Europe</geographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a hierarchical geographic subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "value": 'North America',
              "type": 'continent'
            },
            {
              "value": 'Canada',
              "type": 'country'
            },
            {
              "value": 'Vancouver',
              "type": 'city'
            }
          ],
          "type": 'place'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <hierarchicalGeographic>
              <continent>North America</continent>
              <country>Canada</country>
              <city>Vancouver</city>              
            </hierarchicalGeographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a hierarchical geographic subject missing some hierarchies' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "value": 'Africa',
              "type": 'continent'
            }
          ],
          "type": 'place'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <hierarchicalGeographic>
              <continent>Africa</continent>
            </hierarchicalGeographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a geographic code subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "code": 'n-us-md',
          "type": 'place',
          "source": {
            "code": 'marcgac'
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
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a geographic code and term' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "parallelValue": [
              {
                "value": 'United States',
                "source": {
                  "code": 'lcsh'
                }
              },
              {
                "code": 'us',
                "source": {
                  "code": 'iso3166'
                }
              }
            ],
            "type": 'place'
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
            <geographic authority="lcsh">United States</geographic>
            <geographicCode authority="iso3166">us</geographicCode>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a geographic subject with valueURI and authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Antarctica',
            "uri": 'http://id.loc.gov/authorities/subjects/sh85005490',
            "source": {
              "code": 'lcsh',
              "uri": 'http://id.loc.gov/authorities/subjects/'
            },
            "type": 'place'
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
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">Antarctica</geographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a geographic subject with language' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Arctic Ocean',
            "valueLanguage": {
              "code": 'eng',
              "source": {
                "code": 'iso639-2b'
              }
            },
            "uri": 'http://sws.geonames.org/2960860/',
            "source": {
              "code": 'geonames',
              "uri": 'http://www.geonames.org/ontology#'
            },
            "type": 'place'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="geonames">
            <geographic lang="eng" valueURI="http://sws.geonames.org/2960860/" authorityURI="http://www.geonames.org/ontology#" authority="geonames">Arctic Ocean</geographic>
          </subject>
        </mods>
      XML
    end
  end
end
