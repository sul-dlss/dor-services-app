# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Access do
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

  context 'with a physical repository without authority and valueURI' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "accessContact": [
            {
              "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
              "type": 'repository'
            }
          ],
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
            }
          ]
        }
      )
    end
  end

  context 'with a URL (without usage)' do
    let(:xml) do
      <<~XML
        <location>
          <url>https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "url": [
          {
            "value": 'https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000'
          }
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  context 'with multiple PURLs' do
    let(:xml) do
      <<~XML
        <location>
          <url usage="primary display" note="Available to Stanford-affiliated users.">http://purl.stanford.edu/nd782fm8171</url>
        </location>
        <location>
          <url note="Available to Hoover-affiliated users.">http://purl.stanford.edu/qm814cd3342</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "url": [
          {
            "value": 'http://purl.stanford.edu/qm814cd3342',
            "note": [
              {
                "value": 'Available to Hoover-affiliated users.'
              }
            ]
          }
        ],
        "note": [
          {
            "value": 'Available to Stanford-affiliated users.',
            "type": 'purl access'
          }
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  context 'with Physical location with display label - two location elements' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" displayLabel="Repository" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
        </location>
        <location>
          <physicalLocation>Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "type": 'repository',
            "displayLabel": 'Repository',
            "source": {
              "uri": 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        "physicalLocation": [
          {
            "value": 'Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3'
          }
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  # https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/256
  context 'with a displayLabel' do
    let(:xml) do
      <<~XML
        <accessCondition displayLabel="CC License Type" type='license'>CC by: CC BY Attribution</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          note: [
            {
              value: 'CC by: CC BY Attribution',
              displayLabel: 'CC License Type',
              type: 'license'
            }
          ]
        }
      )
    end
  end
end
