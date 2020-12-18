# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Access do
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

  # most examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_location.txt
  # example 1 from mods_to_cocina_location.txt
  context 'with a physical location term (with authority)' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/nb2006009317">British Broadcasting Corporation. Sound Effects Library</physicalLocation>
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

  # example 2 from mods_to_cocina_location.txt
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

  # example 3 from mods_to_cocina_location.txt
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
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
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

  # example 9 from mods_to_cocina_location.txt
  context 'with a physical repository with language and script' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980" lang="eng" script="Latn">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
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
              "uri": 'http://id.loc.gov/authorities/names/no2014019980',
              "type": 'repository',
              "source": {
                "code": 'naf'
              }
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

  # example 4 from mods_to_cocina_location.txt
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
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
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
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  # example 5 from mods_to_cocina_location.txt ???  If so, wrong result
  context 'with a URL to purl' do
    let(:xml) do
      <<~XML
        <location>
          <url usage="primary display">http://purl.stanford.edu/ys701qw6956</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        # purl: 'http://purl.stanford.edu/ys701qw6956', # see note above context block
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  # example 14 from mods_to_cocina_location
  context 'with a URL to purl' do
    let(:xml) do
      <<~XML
        <location>
          <url displayLabel="electronic resource" usage="primary display" note="Available to Stanford-affiliated users.">http://purl.stanford.edu/nd782fm8171</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
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

  # example 8 from mods_to_cocina_location.txt
  context 'with a URL with note' do
    let(:xml) do
      <<~XML
        <location>
          <url displayLabel="Coverage: V. 1 (Jan. 1922)-" note="Online table of contents from PCI available to Stanford-affiliated users:">https://stanford.idm.oclc.org/login</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
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
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  # example 6 from mods_to_cocina_location.txt
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

  # example 7 from mods_to_cocina_location.txt
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

  # example 10 from mods_to_cocina_location.txt
  context 'with Physical location with type "discovery" mapping to digitalLocation' do
    let(:xml) do
      <<~'XML'
        <location>
          <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives.</physicalLocation>
          <physicalLocation type="discovery">VICTOR\PLUS_PHOTOS_DAN\PLUS_TARD_PHOTOS_DAN_20071017\IMG_0852.JPG</physicalLocation>
          <url usage="primary display">http://purl.stanford.edu/hn970dy7259</url>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "accessContact": [
            {
              "value": 'Stanford University. Libraries. Department of Special Collections and University Archives.',
              "type": 'repository',
              "uri": 'http://id.loc.gov/authorities/names/no2014019980',
              "source": {
                "code": 'naf'
              }
            }
          ],
          "digitalLocation": [
            {
              "value": 'VICTOR\PLUS_PHOTOS_DAN\PLUS_TARD_PHOTOS_DAN_20071017\IMG_0852.JPG',
              "type": 'discovery'
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

  # example 11 from mods_to_cocina_location.txt
  context 'with Physical location with display label' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" displayLabel="Repository" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          <physicalLocation>Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3</physicalLocation>
        </location>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        accessContact: [
          {
            value: 'Stanford University. Libraries. Department of Special Collections and University Archives',
            uri: 'http://id.loc.gov/authorities/names/no2014019980',
            type: 'repository',
            displayLabel: 'Repository',
            source: {
              uri: 'http://id.loc.gov/authorities/names/'
            }
          }
        ],
        physicalLocation: [
          {
            value: 'Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3'
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

  # example 12 from mods_to_cocina_location.txt
  context 'with multiple locations and URLs with usage="primary display"' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_location.txt#L308'
  end

  # example 13 from mods_to_cocina_location.txt
  context 'with physical location with type "location"' do
    let(:xml) do
      <<~XML
        <location>
          <physicalLocation type="repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          <physicalLocation type="location">Box: 20, Folder: Engineering laboratories -- exterior -- #1</physicalLocation>
          <shelfLocator>SC1071</shelfLocator>
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
        ],
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      )
    end
  end

  # examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_accessCondition.txt

  # example 1A from mods_to_cocina_accessCondition.txt
  context 'with a restriction on access' do
    let(:xml) do
      <<~XML
        <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'Available to Stanford researchers only.',
              "type": 'access restriction'
            }
          ]
        }
      )
    end
  end

  # example 1B from mods_to_cocina_accessCondition.txt
  context 'with a restriction on access without spaces' do
    let(:xml) do
      <<~XML
        <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'Available to Stanford researchers only.',
              "type": 'access restriction'
            }
          ]
        }
      )
    end
  end

  # example 2A from mods_to_cocina_accessCondition.txt
  context 'with a restriction on use and reproduction' do
    let(:xml) do
      <<~XML
        <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.',
              "type": 'use and reproduction'
            }
          ]
        }
      )
    end
  end

  # example 2B from mods_to_cocina_accessCondition.txt
  context 'with a restriction on use and reproduction without spaces' do
    let(:xml) do
      <<~XML
        <accessCondition type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.',
              "type": 'use and reproduction'
            }
          ]
        }
      )
    end
  end

  # example 3 from mods_to_cocina_accessCondition.txt
  context 'with a license' do
    let(:xml) do
      <<~XML
        <accessCondition type="license">CC by: CC BY Attribution</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'CC by: CC BY Attribution',
              "type": 'license'
            }
          ]
        }
      )
    end
  end
end
