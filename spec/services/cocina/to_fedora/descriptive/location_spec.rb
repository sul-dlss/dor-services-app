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

  # example 1 from mods_to_cocina_location.txt
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
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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
            <physicalLocation authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/nb2006009317" authority="lcsh">British Broadcasting Corporation. Sound Effects Library</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  # example 2 from mods_to_cocina_location.txt
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
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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

  # example 3 from mods_to_cocina_location.txt
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
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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

  # example 9 from mods_to_cocina_location.txt
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

  # example 4 from mods_to_cocina_location.txt
  context 'when it is a URL (with usage)' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "url": [
          {
            "value": 'https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000',
            "status": 'primary'
          }
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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

  # example 8 from mods_to_cocina_location.txt
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
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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

  # example 5 from mods_to_cocina_location.txt - but not exactly
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

  # example 14 from mods_to_cocina_location.txt
  context 'when it is a PURL with note' do
    let(:purl) { 'http://purl.stanford.edu/nd782fm8171' }

    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "note": [
          {
            "value": 'Available to Stanford-affiliated users.',
            "type": 'purl access'
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
            <url usage="primary display" note="Available to Stanford-affiliated users.">http://purl.stanford.edu/nd782fm8171</url>
          </location>
        </mods>
      XML
    end
  end

  # example 6 from mods_to_cocina_location.txt
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
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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

  # example 7 from mods_to_cocina_location.txt
  context 'when it is a shelf locator' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "physicalLocation": [
          {
            "value": 'SC080',
            "type": 'shelf locator'
          }
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "type": 'repository',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "source": {
              "code": 'naf',
              "uri": 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        "url": [
          {
            "value": 'https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
            "displayLabel": 'Archived website'
          },
          {
            "value": 'https://second.swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
            "displayLabel": 'Second Archived website'
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

  # example 10 from mods_to_cocina_location.txt
  context 'with Physical location with type "discovery" mapping to digitalLocation' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_location.txt#L227'
  end

  # example 11 from mods_to_cocina_location.txt
  context 'with Physical location with display label' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "type": 'repository',
            "displayLabel": 'Repository',
            "source": {
              "code": 'naf',
              "uri": 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        "physicalLocation": [
          {
            "value": 'Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3'
          }
        ],
        "digitalRepository": [
          {
            "value": 'Stanford Digital Repository'
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
            <physicalLocation type="repository" displayLabel="Repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
          <location>
            <physicalLocation>Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3</physicalLocation>
          </location>
        </mods>
      XML
    end
  end

  # example 12 from mods_to_cocina_location.txt
  context 'with multiple locations and URLs with usage="primary display"' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_location.txt#L308'
  end

  # example 13 from mods_to_cocina_location.txt
  context 'with physical location with type "location"' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "accessContact": [
          {
            "value": 'Stanford University. Libraries. Department of Special Collections and University Archives',
            "type": 'repository',
            "uri": 'http://id.loc.gov/authorities/names/no2014019980',
            "source": {
              "code": 'naf',
              "uri": 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        "physicalLocation": [
          {
            "value": 'Box: 20, Folder: Engineering laboratories -- exterior -- #1',
            "type": 'location'
          },
          {
            "value": 'SC1071',
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
            <physicalLocation type="repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
          <location>
            <physicalLocation type="location">Box: 20, Folder: Engineering laboratories -- exterior -- #1</physicalLocation>
          </location>
          <location>
            <shelfLocator>SC1071</shelfLocator>
          </location>
        </mods>
      XML
    end
  end
end
