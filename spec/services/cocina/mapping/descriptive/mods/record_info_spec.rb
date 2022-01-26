# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS recordInfo <--> cocina mappings' do
  describe 'From replayable spreadsheet' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <languageOfCataloging usage="primary">
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
              <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
              <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
              <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
            </languageOfCataloging>
            <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/"
              valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
            <descriptionStandard authority="dacs" authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/"
              valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs"></descriptionStandard>
            <descriptionStandard>aacr</descriptionStandard>
            <recordOrigin>human prepared</recordOrigin>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            language: [
              {
                status: 'primary',
                value: 'English',
                code: 'eng',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
                source: {
                  code: 'iso639-2b',
                  uri: 'http://id.loc.gov/vocabulary/iso639-2/'
                },
                script: {
                  value: 'Latin',
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              }
            ],
            contributor: [
              {
                name: [
                  {
                    code: 'CSt',
                    uri: 'http://id.loc.gov/vocabulary/organizations/cst',
                    source: {
                      code: 'marcorg',
                      uri: 'http://id.loc.gov/vocabulary/organizations/'
                    }
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'original cataloging agency'
                  }
                ]
              }
            ],
            metadataStandard: [
              {
                uri: 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
                source: {
                  uri: 'http://id.loc.gov/vocabulary/descriptionConventions/',
                  # This isn't really the code for the authority. However, carrying through bad data.
                  code: 'dacs'
                }
              },
              {
                code: 'aacr'
              }
            ],
            note: [
              {
                type: 'record origin',
                value: 'human prepared'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Multilingual' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <languageOfCataloging usage="primary">
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
              <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
              <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
              <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
            </languageOfCataloging>
            <languageOfCataloging>
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/chi">Chinese</languageTerm>
              <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
                valueURI="http://id.loc.gov/vocabulary/iso639-2/chi">chi</languageTerm>
              <scriptTerm type="text" authority="iso15924">Han (Simplified variant)</scriptTerm>
              <scriptTerm type="code" authority="iso15924">Hans</scriptTerm>
            </languageOfCataloging>
            <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/"
              valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            language: [
              {
                value: 'English',
                code: 'eng',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
                source: {
                  code: 'iso639-2b',
                  uri: 'http://id.loc.gov/vocabulary/iso639-2/'
                },
                script: {
                  value: 'Latin',
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                },
                status: 'primary'
              },
              {
                value: 'Chinese',
                code: 'chi',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/chi',
                source: {
                  code: 'iso639-2b',
                  uri: 'http://id.loc.gov/vocabulary/iso639-2/'
                },
                script: {
                  value: 'Han (Simplified variant)',
                  code: 'Hans',
                  source: {
                    code: 'iso15924'
                  }
                }
              }
            ],
            contributor: [
              {
                name: [
                  {
                    code: 'CSt',
                    uri: 'http://id.loc.gov/vocabulary/organizations/cst',
                    source: {
                      code: 'marcorg',
                      uri: 'http://id.loc.gov/vocabulary/organizations/'
                    }
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'original cataloging agency'
                  }
                ]
              }
            ]
          }
        }
      end
    end
  end

  describe 'Description standard with authority' do
    # Adapted from fw201vw9681
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <descriptionStandard authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dcrmg">dcrmg</descriptionStandard>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            metadataStandard: [
              {
                code: 'dcrmg',
                uri: 'http://id.loc.gov/vocabulary/descriptionConventions/dcrmg',
                source: {
                  uri: 'http://id.loc.gov/vocabulary/descriptionConventions/'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'Converted from MARC' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <descriptionStandard>aacr</descriptionStandard>
            <recordContentSource authority="marcorg">CSt</recordContentSource>
            <recordCreationDate encoding="marc">180305</recordCreationDate>
            <recordChangeDate encoding="iso8601">20200718050001.0</recordChangeDate>
            <recordIdentifier source="SIRSI">a12374669</recordIdentifier>
            <recordOrigin>Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7.xsl</recordOrigin>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            contributor: [
              {
                name: [
                  {
                    code: 'CSt',
                    source: {
                      code: 'marcorg'
                    }
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'original cataloging agency'
                  }
                ]
              }
            ],
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '180305',
                    encoding: {
                      code: 'marc'
                    }
                  }
                ]
              },
              {
                type: 'modification',
                date: [
                  {
                    value: '20200718050001.0',
                    encoding: {
                      code: 'iso8601'
                    }
                  }
                ]
              }
            ],
            metadataStandard: [
              {
                code: 'aacr'
              }
            ],
            identifier: [
              {
                value: 'a12374669',
                type: 'SIRSI'
              }
            ],
            note: [
              {
                type: 'record origin',
                value: 'Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7.xsl'
              }
            ],
            language: [
              {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'Converted from ISO 19139' do
    xit 'not implemented: recordContentSource is a value, not a code ...' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <recordContentSource>Stanford</recordContentSource>
            <recordIdentifier>edu.stanford.purl:ft445st6184</recordIdentifier>
            <recordOrigin>This record was translated from ISO 19139 to MODS v.3 using an xsl transformation.</recordOrigin>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            contributor: [
              {
                name: [
                  {
                    value: 'Stanford'
                  }
                ]
              }
            ],
            identifier: [
              {
                value: 'edu.stanford.purl:ft445st6184'
              }
            ],
            note: [
              {
                type: 'record origin',
                value: 'This record was translated from ISO 19139 to MODS v.3 using an xsl transformation.'
              }
            ],
            language: [
              {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'From Metadata Toolkit (2012)' do
    # Adapted from pc933rc9605
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <languageOfCataloging>
              <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
            </languageOfCataloging>
            <recordContentSource authority="marcorg">CSt</recordContentSource>
            <recordContentSource>Lyberteam Metadata ToolKit</recordContentSource>
            <recordCreationDate encoding="iso8601">2012-05-23T22:30:52.571Z</recordCreationDate>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            language: [
              {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                }
              }
            ],
            contributor: [
              # If authority="marcorg", treat it as a code
              {
                name: [
                  {
                    code: 'CSt',
                    source: {
                      code: 'marcorg'
                    }
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'original cataloging agency'
                  }
                ]
              },
              # Otherwise treat it as text
              {
                name: [
                  {
                    value: 'Lyberteam Metadata ToolKit'
                  }
                ]
              }
            ],
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '2012-05-23T22:30:52.571Z',
                    encoding: {
                      code: 'iso8601'
                    }
                  }
                ]
              }
            ]
          }
        }
      end
    end
  end

  describe 'Note links to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <recordInfoNote xlink:href="http://note.org/recordinfonote" />
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            note: [
              {
                valueAt: 'http://note.org/recordinfonote'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Language term text only' do
    # Adapted from rb670yb8840
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <languageOfCataloging>
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            language: [
              {
                value: 'English',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
                source: {
                  code: 'iso639-2b',
                  uri: 'http://id.loc.gov/vocabulary/iso639-2'
                }
              }
            ]
          }
        }
      end
    end
  end

  describe 'With recordInfoNote' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <recordInfoNote>Modified from source.</recordInfoNote>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            note: [
              {
                value: 'Modified from source.',
                type: 'record information'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Multiple modification dates' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <recordInfo>
            <recordCreationDate encoding="marc">761020</recordCreationDate>
            <recordChangeDate encoding="iso8601">19900913000000.0</recordChangeDate>
            <recordChangeDate encoding="iso8601">19900905000000.0</recordChangeDate>
          </recordInfo>
        XML
      end

      let(:cocina) do
        {
          adminMetadata: {
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '761020',
                    encoding: {
                      code: 'marc'
                    }
                  }
                ]
              },
              {
                type: 'modification',
                date: [
                  {
                    value: '19900913000000.0',
                    encoding: {
                      code: 'iso8601'
                    }
                  }
                ]
              },
              {
                type: 'modification',
                date: [
                  {
                    value: '19900905000000.0',
                    encoding: {
                      code: 'iso8601'
                    }
                  }
                ]
              }
            ]
          }
        }
      end
    end
  end
end
