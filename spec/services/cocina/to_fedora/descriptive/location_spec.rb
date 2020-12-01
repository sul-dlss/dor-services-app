# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Location do
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

  context 'when it is a physical location term (with authority)' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
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
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <physicalLocation authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/nb2006009317">British Broadcasting Corporation. Sound Effects Library</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a physical location code' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "physicalLocation": [
          {
            "code": 'CSt',
            "source": {
              "code": 'marcorg'
            }
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
            <physicalLocation authority="marcorg">CSt</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a physical repository' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a physical repository with language and script' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "valueLanguage": {
              "code": 'eng',
              "source": {
                "code": 'iso639-2b'
              },
              "valueScript": {
                "code": 'Latn',
                "source": {
                  "code": 'iso15924'
                }
              }
            },
            "type": 'repository',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "source": {
              "code": 'naf'
            }
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
            <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980" lang="eng" script="Latn">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a URL (with usage)' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "url": [
          {
            "value": 'https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000',
            "status": 'primary'
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
            <url usage="primary display">https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a URL with note' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "url": [
          {
            "value": 'https://stanford.idm.oclc.org/login',
            "displayLabel": 'Coverage: V. 1 (Jan. 1922)-',
            "note": [
              {
                "value": 'Online table of contents from PCI available to Stanford-affiliated users:'
              }
            ]
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
            <url displayLabel="Coverage: V. 1 (Jan. 1922)-" note="Online table of contents from PCI available to Stanford-affiliated users:">https://stanford.idm.oclc.org/login</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a PURL' do
    let(:purl) { 'http://purl.stanford.edu/ys701qw6956' }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url usage="primary display">http://purl.stanford.edu/ys701qw6956</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a Web archive (with display label)' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
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
      )
    end

    let(:purl) { 'http://purl.stanford.edu/hf898mn6942' }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/n81070667">Stanford University. Libraries</physicalLocation>
          </location>
          <location>
            <url usage="primary display">http://purl.stanford.edu/hf898mn6942</url>
          </location>
          <location>
            <url displayLabel="Archived website">https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when it is a shelf locator' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "physicalLocation": [
          {
            "value": 'SC080',
            "type": 'shelf locator'
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
            <shelfLocator>SC080</shelfLocator>
          </location>
        </mods>
      XML
    end
  end

  context 'when it has multiple URLs' do
    let(:purl) { 'http://purl.stanford.edu/cy979mw6316' }
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "url": [
          {
            "value": 'http://infoweb.newsbank.com/?db=SERIAL',
            "status": 'primary'
          },
          {
            "value": 'http://web.lexis-nexis.com/congcomp/form/cong/s_pubadvanced.html?srcboxes=SSMaps&srcboxes=SerialSet'
          },
          {
            "value": 'http://purl.access.gpo.gov/GPO/LPS839'
          }
        ],
        "physicalLocation": [
          {
            "code": 'Stanford University Libraries'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <?xml version=\"1.0\"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <physicalLocation>Stanford University Libraries</physicalLocation>
          </location>
          <location>
            <url usage="primary display">http://purl.stanford.edu/cy979mw6316</url>
          </location>
          <location>
            <url>http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
          <location>
            <url>http://web.lexis-nexis.com/congcomp/form/cong/s_pubadvanced.html?srcboxes=SSMaps&amp;srcboxes=SerialSet</url>
          </location>
          <location>
            <url>http://purl.access.gpo.gov/GPO/LPS839</url>
          </location>
        </mods>
      XML
    end
  end
end
