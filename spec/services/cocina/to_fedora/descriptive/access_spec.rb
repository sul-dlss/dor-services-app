# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Access do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, access: access, purl: purl)
      end
    end
  end

  let(:purl) { nil }
  let(:access) { nil }

  # most examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_location.txt

  context 'when location and PURL is nil' do
    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when there is a PURL and a primary display URL' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        url: [
          {
            value: 'http://www.jgp.org/',
            status: 'primary',
            note: [
              {
                value: 'Available to Stanford-affiliated users at:'
              }
            ]
          }
        ]
      )
    end

    let(:purl) { 'http://purl.stanford.edu/dq628sb8161' }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url>http://purl.stanford.edu/dq628sb8161</url>
          </location>
          <location>
            <url usage="primary display" note="Available to Stanford-affiliated users at:">http://www.jgp.org/</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when it has multiple URLs with display labels' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        accessContact: [
          {
            value: 'Stanford University. Libraries. Department of Special Collections and University Archives',
            type: 'repository',
            uri: 'http://id.loc.gov/authorities/names/no2014019980',
            source: {
              code: 'naf',
              uri: 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        url: [
          {
            value: 'https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
            displayLabel: 'Archived website'
          },
          {
            value: 'https://second.swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
            displayLabel: 'Second Archived website'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <physicalLocation type="repository" valueURI="http://id.loc.gov/authorities/names/no2014019980" authorityURI="http://id.loc.gov/authorities/names/" authority="naf">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
          <location>
            <url displayLabel="Archived website">https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
          </location>
          <location>
            <url displayLabel="Second Archived website">https://second.swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
          </location>
        </mods>
      XML
    end
  end

  # Access condition mapping
  context 'when access_conditions is nil' do
    let(:access) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  # https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/256
  context 'when the accessCondition has a displayLabel attribute' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        note: [
          {
            value: 'CC by: CC BY Attribution',
            displayLabel: 'CC License Type',
            type: 'license'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition displayLabel="CC License Type" type='license'>CC by: CC BY Attribution</accessCondition>
        </mods>
      XML
    end
  end
end
