# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
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

  context 'with a geographic subject subdivision' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <geographic>Europe</geographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Europe',
              "type": 'place'
            }
          ]
        }
      ]
    end
  end

  context 'with a hierarchical geographic subject subdivision' do
    let(:xml) do
      <<~XML
          <subject>
            <hierarchicalGeographic>
              <country>Austria</country>
              <city>Vienna</city>
            </hierarchicalGeographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Austria',
              "type": 'country'
            },
            {
              "value": 'Vienna',
              "type": 'city'
            }
          ],
          "type": 'place'
        }
      ]
    end
  end

  context 'with a geographic code subject' do
    let(:xml) do
      <<~XML
        <subject>
          <geographicCode authority="marcgac">n-us-md</geographicCode>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "code": 'n-us-md',
          "type": 'place',
          "source": {
            "code": 'marcgac'
          }
        }
      ]
    end
  end

  context 'with geographic code and term' do
    let(:xml) do
      <<~XML
        <subject>
          <geographic authority="lcsh">United States</geographic>
          <geographicCode authority="iso3166">us</geographicCode>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
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
      ]
    end
  end

  context 'with geographic subject with valueURI and authority' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">
          <geographic>Antarctica</geographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Antarctica',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85005490',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          },
          "type": 'place'
        }
      ]
    end
  end

  context 'with geographic subject with language' do
    let(:xml) do
      <<~XML
        <subject>
          <geographic lang="eng" valueURI="http://sws.geonames.org/2960860/" authority="geonames" authorityURI="http://www.geonames.org/ontology#">Arctic Ocean</geographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
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
      ]
    end
  end
end
