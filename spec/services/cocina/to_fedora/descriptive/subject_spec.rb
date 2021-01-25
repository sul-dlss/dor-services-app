# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  subject(:xml) { writer.to_xml }

  let(:forms) { [] }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, subjects: subjects, forms: forms, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when subject is nil' do
    let(:subjects) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with authority but no authorityURI' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
            "source": {
              "code": 'lcsh'
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
            <topic authority="lcsh" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with non-lcsh authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "source": {
              "code": 'mesh'
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
          <subject authority="mesh">
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with authority but no valueURI' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "source": {
              "code": 'lcsh'
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
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a cartographic subject with valueURI and authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        )
      ]
    end

    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1:22,000,000',
            "type": 'map scale'
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Conic proj',
            "type": 'map projection',
            "uri": 'http://opengis.net/def/crs/EPSG/0/4326',
            "source": {
              "code": 'EPSG'
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
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326">
            <cartographics>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a cartographic subject without forms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
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
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'with a parallel subject but different types' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "parallelValue": [
              {
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/subjects/'
                },
                "uri": 'http://id.loc.gov/authorities/subjects/sh85135212',
                "value": 'Tiber River (Italy)',
                "type": 'place'
              },
              {
                "source": {
                  "code": 'local'
                },
                "value": 'Tevere',
                "type": 'topic'
              },
              {
                "value": 'Tiber River',
                "type": 'name',
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/names/'
                },
                "uri": 'http://id.loc.gov/authorities/names/n97042879'
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
          <subject authority="lcsh" altRepGroup="1">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85135212">Tiber River (Italy)</geographic>
          </subject>
          <subject authority="local" altRepGroup="1">
            <topic>Tevere</topic>
          </subject>
          <subject authority="lcsh" altRepGroup="1">
            <name authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97042879">
              <namePart>Tiber River</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a subject with lang and script' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "structuredValue": [
              {
                "value": 'Archives et documents',
                "type": 'topic'
              },
              {
                "value": 'Portraits',
                "type": 'topic'
              }
            ],
            "valueLanguage": {
              "code": 'fre',
              "source": {
                "code": 'iso639-2b'
              },
              valueScript: {
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            },
            "displayLabel": 'French archives'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject lang="fre" script="Latn" displayLabel="French archives">
            <topic>Archives et documents</topic>
            <topic>Portraits</topic>
          </subject>
        </mods>
      XML
    end
  end
end
