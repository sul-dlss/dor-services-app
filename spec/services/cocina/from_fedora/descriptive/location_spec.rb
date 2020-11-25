# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Location do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a physical location term (with authority)' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation authority="lcsh" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/nb2006009317">British Broadcasting Corporation. Sound Effects Library</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "physicalLocation": [
            {
              "value": 'British Broadcasting Corporation. Sound Effects Library',
              "uri": 'http://id.loc.gov/authorities/names/nb2006009317',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      )
    end
  end

  context 'with a physical location code' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation authority="marcorg">CSt</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "physicalLocation": [
            {
              "code": 'CSt',
              "source": {
                "code": 'marcorg'
              }
            }
          ]
        }
      )
    end
  end

  context 'with a physical repository' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "type": 'repository',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "source": {
              "code": 'naf'
            }
          }
        ]
      )
    end
  end

  context 'with a URL (with usage)' do
    let(:xml) do
      <<~XML
        <location>
          <url usage="primary display">https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "url": [
          {
            "value": 'https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000',
            "status": 'primary'
          }
        ]
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
        ]
      )
    end
  end

  context 'with a URL (without usage)' do
    let(:xml) do
      <<~XML
        <location>
          <url usage="primary display">http://purl.stanford.edu/ys701qw6956</url>
        </location>
      XML
    end

    it 'ignores' do
      expect(build).to eq({})
    end
  end

  context 'with a Web archive (with display label)' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/n81070667">Stanford University. Libraries</physicalLocation>
          <url usage="primary display">http://purl.stanford.edu/hf898mn6942</url>
          <url displayLabel="Archived website">https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "accessContact": [
            {
              "value": 'Stanford University. Libraries',
              "type": 'repository',
              "uri": 'http://id.loc.gov/authorities/names/n81070667',
              "source": {
                "code": 'naf'
              }
            }
          ],
          "url": [
            {
              "value": 'https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
              "displayLabel": 'Archived website'
            }
          ]
        }
      )
    end
  end

  context 'with a Shelf locator' do
    let(:xml) do
      <<~XML
        <location>
          <shelfLocator>SC080</shelfLocator>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "physicalLocation": [
            {
              "value": 'SC080',
              "type": 'shelf locator'
            }
          ]
        }
      )
    end
  end
end
