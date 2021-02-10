# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS location <--> cocina mappings' do
  describe 'Physical location term (with authority)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/nb2006009317"
              >British Broadcasting Corporation. Sound Effects Library</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            physicalLocation: [
              {
                value: 'British Broadcasting Corporation. Sound Effects Library',
                uri: 'http://id.loc.gov/authorities/names/nb2006009317',
                source: {
                  code: 'lcsh',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'Physical location code' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation authority="marcorg">CSt</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            physicalLocation: [
              {
                code: 'CSt',
                source: {
                  code: 'marcorg'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'Physical repository' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" authority="naf"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            accessContact: [
              {
                value: 'Stanford University. Libraries. Department of Special Collections and University Archives',
                type: 'repository',
                uri: 'http://id.loc.gov/authorities/names/no2014019980',
                source: {
                  code: 'naf'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'URL (with usage)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <url usage="primary display"
              >https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            url: [
              {
                value: 'https://www.davidrumsey.com/luna/servlet/view/search?q=pub_list_no=%2211728.000',
                status: 'primary'
              }
            ]
          }
        }
      end
    end
  end

  describe 'PURL' do
    # if purl is only url in record or no other url has usage="primary display", assign to purl
    it_behaves_like 'MODS cocina mapping' do
      let(:druid) { 'ys701qw6956' }

      let(:mods) do
        <<~XML
          <location>
            <url usage="primary display">http://purl.stanford.edu/ys701qw6956</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/ys701qw6956',
          access: {
            digitalRepository: [
              value: 'Stanford Digital Repository'
            ]
          }
        }
      end
    end
  end

  describe 'Web archive (with display label)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:druid) { 'hf898mn6942' }

      let(:mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" authority="naf"
              valueURI="http://id.loc.gov/authorities/names/n81070667">Stanford University. Libraries</physicalLocation>
            <url usage="primary display">http://purl.stanford.edu/hf898mn6942</url>
            <url displayLabel="Archived website"
              >https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
          </location>
        XML
      end

      # separate location elements
      let(:roundtrip_mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" authority="naf"
              valueURI="http://id.loc.gov/authorities/names/n81070667">Stanford University. Libraries</physicalLocation>
          </location>
          <location>
            <url usage="primary display">http://purl.stanford.edu/hf898mn6942</url>
          </location>
          <location>
            <url displayLabel="Archived website"
              >https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/hf898mn6942',
          access: {
            accessContact: [
              {
                value: 'Stanford University. Libraries',
                type: 'repository',
                uri: 'http://id.loc.gov/authorities/names/n81070667',
                source: {
                  code: 'naf'
                }
              }
            ],
            url: [
              {
                value: 'https://swap.stanford.edu/20171107174354/https://www.le.ac.uk/english/em1060to1220/index.html',
                displayLabel: 'Archived website'
              }
            ],
            digitalRepository: [
              value: 'Stanford Digital Repository'
            ]
          }
        }
      end
    end
  end

  describe 'Shelf locator' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <shelfLocator>SC080</shelfLocator>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            physicalLocation: [
              {
                value: 'SC080',
                type: 'shelf locator'
              }
            ]
          }
        }
      end
    end
  end

  describe 'URL with note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <url displayLabel="Coverage: V. 1 (Jan. 1922)-"
              note="Online table of contents from PCI available to Stanford-affiliated users:"
              >https://stanford.idm.oclc.org/login?url=http://gateway.proquest.com/openurl?blah</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            url: [
              {
                value: 'https://stanford.idm.oclc.org/login?url=http://gateway.proquest.com/openurl?blah',
                displayLabel: 'Coverage: V. 1 (Jan. 1922)-',
                note: [
                  value: 'Online table of contents from PCI available to Stanford-affiliated users:'
                ]
              }
            ]
          }
        }
      end
    end
  end

  describe 'Physical location with language and script' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" lang="eng" script="Latn"
              authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            accessContact: [
              {
                value: 'Stanford University. Libraries. Department of Special Collections and University Archives',
                type: 'repository',
                valueLanguage: {
                  code: 'eng',
                  source: {
                    code: 'iso639-2b'
                  },
                  valueScript: {
                    code: 'Latn',
                    source: {
                      code: 'iso15924'
                    }
                  }
                },
                uri: 'http://id.loc.gov/authorities/names/no2014019980',
                source: {
                  code: 'naf'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'Physical location with type "discovery" mapping to digitalLocation' do
    # Map MODS physicalLocation to COCINA digitalLocation if the value contains / or \.
    it_behaves_like 'MODS cocina mapping' do
      let(:druid) { 'hn970dy7259' }

      let(:mods) do
        <<~'XML'
          <location>
            <physicalLocation type="repository" authority="naf"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives.</physicalLocation>
            <physicalLocation type="discovery">VICTOR\PLUS_PHOTOS_DAN\PLUS_TARD_PHOTOS_DAN_20071017\IMG_0852.JPG</physicalLocation>
            <url usage="primary display">http://purl.stanford.edu/hn970dy7259</url>
          </location>
        XML
      end

      # separate location elements
      let(:roundtrip_mods) do
        <<~'XML'
          <location>
            <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives.</physicalLocation>
          </location>
          <location>
            <physicalLocation type="discovery">VICTOR\PLUS_PHOTOS_DAN\PLUS_TARD_PHOTOS_DAN_20071017\IMG_0852.JPG</physicalLocation>
          </location>
          <location>
            <url usage="primary display">http://purl.stanford.edu/hn970dy7259</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/hn970dy7259',
          access: {
            accessContact: [
              {
                value: 'Stanford University. Libraries. Department of Special Collections and University Archives.',
                type: 'repository',
                uri: 'http://id.loc.gov/authorities/names/no2014019980',
                source: {
                  code: 'naf'
                }
              }
            ],
            digitalLocation: [
              {
                value: 'VICTOR\PLUS_PHOTOS_DAN\PLUS_TARD_PHOTOS_DAN_20071017\IMG_0852.JPG',
                type: 'discovery'
              }
            ],
            digitalRepository: [
              value: 'Stanford Digital Repository'
            ]
          }
        }
      end
    end
  end

  describe 'Physical location with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" displayLabel="Repository"
              authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
            <physicalLocation>Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3</physicalLocation>
          </location>
        XML
      end

      # separate location elements
      let(:roundtrip_mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" displayLabel="Repository"
              authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
          <location>
            <physicalLocation>Call Number: SC0340, Accession 2005-101, Box: 51, Folder: 3</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
            accessContact: [
              {
                value: 'Stanford University. Libraries. Department of Special Collections and University Archives',
                type: 'repository',
                uri: 'http://id.loc.gov/authorities/names/no2014019980',
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
            ]
          }
        }
      end
    end
  end

  describe 'Multiple locations and non-purl with usage="primary display"' do
    it_behaves_like 'MODS cocina mapping' do
      let(:druid) { 'cy979mw6316' }

      let(:mods) do
        <<~XML
          <location>
            <url usage="primary display" note="Available to Stanford-affiliated users at READEX:"
              >http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
          <location>
            <url note="Available to Stanford-affiliated users at:"
              >http://web.lexis-nexis.com/congcomp/form/cong/s_pubadvanced.html?srcboxes=SSMaps&amp;srcboxes=SerialSet</url>
          </location>
          <location>
            <url>http://purl.access.gpo.gov/GPO/LPS839</url>
          </location>
          <location>
            <physicalLocation>Stanford University Libraries</physicalLocation>
            <url>http://purl.stanford.edu/cy979mw6316</url>
          </location>
        XML
      end

      # physicalLocation goes in same location element as Stanford purl
      let(:roundtrip_mods) do
        <<~XML
          <location>
            <url note="Available to Stanford-affiliated users at READEX:" usage="primary display"
              >http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
          <location>
            <url note="Available to Stanford-affiliated users at:"
              >http://web.lexis-nexis.com/congcomp/form/cong/s_pubadvanced.html?srcboxes=SSMaps&amp;srcboxes=SerialSet</url>
          </location>
          <location>
            <url>http://purl.access.gpo.gov/GPO/LPS839</url>
          </location>
          <location>
            <url>http://purl.stanford.edu/cy979mw6316</url>
          </location>
          <location>
            <physicalLocation>Stanford University Libraries</physicalLocation>
          </location>
        XML
      end

      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/cy979mw6316',
          access: {
            url: [
              {
                value: 'http://infoweb.newsbank.com/?db=SERIAL',
                note: [
                  value: 'Available to Stanford-affiliated users at READEX:'
                ],
                status: 'primary'
              },
              {
                value: 'http://web.lexis-nexis.com/congcomp/form/cong/s_pubadvanced.html?srcboxes=SSMaps&srcboxes=SerialSet',
                note: [
                  value: 'Available to Stanford-affiliated users at:'
                ]
              },
              {
                value: 'http://purl.access.gpo.gov/GPO/LPS839'
              }
            ],
            physicalLocation: [
              {
                value: 'Stanford University Libraries'
              }
            ],
            digitalRepository: [
              value: 'Stanford Digital Repository'
            ]
          }
        }
      end
    end
  end

  describe 'Physical location with type "location"' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
            <physicalLocation type="location">Box: 20, Folder: Engineering laboratories -- exterior -- #1</physicalLocation>
            <shelfLocator>SC1071</shelfLocator>
          </location>
        XML
      end

      # separate location elements
      let(:roundtrip_mods) do
        <<~XML
          <location>
            <physicalLocation type="repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/no2014019980"
              >Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
          </location>
          <location>
            <physicalLocation type="location">Box: 20, Folder: Engineering laboratories -- exterior -- #1</physicalLocation>
          </location>
          <location>
            <shelfLocator>SC1071</shelfLocator>
          </location>
        XML
      end

      let(:cocina) do
        {
          access: {
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
            physicalLocation: [
              {
                value: 'Box: 20, Folder: Engineering laboratories -- exterior -- #1',
                type: 'location'
              },
              {
                value: 'SC1071',
                type: 'shelf locator'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Purl with displayLabel and note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:druid) { 'nd782fm8171' }

      let(:mods) do
        <<~XML
          <location>
            <url displayLabel="electronic resource" usage="primary display"
              note="Available to Stanford-affiliated users.">http://purl.stanford.edu/nd782fm8171</url>
          </location>
        XML
      end

      # no displayLabel
      let(:roundtrip_mods) do
        <<~XML
          <location>
            <url usage="primary display"
              note="Available to Stanford-affiliated users.">http://purl.stanford.edu/nd782fm8171</url>
          </location>
        XML
      end

      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/nd782fm8171',
          access: {
            note: [
              {
                value: 'Available to Stanford-affiliated users.',
                type: 'purl access'
              }
            ],
            digitalRepository: [
              value: 'Stanford Digital Repository'
            ]
          }
        }
      end
    end
  end
end
