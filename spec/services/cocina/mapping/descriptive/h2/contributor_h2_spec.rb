# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS contributor mappings (h2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  #
  # First contributor entered in H2 receives "status": "primary", which maps to "usage=primary" in MODS. This attribute indicates that
  # a) Systems should use this name as sort key when sorting by author
  # b) MARC mappings should put this name in the 100 field as main author
  # c) Other applications where a single name must be chosen for a purpose (such as constructing a citation using "et al.") should use this name.
  #
  # DataCite role mappings vary due to its different structure. Most roles map to DataCite contributor types, with the following exceptions:
  # 1) Creator maps to the Creator property
  # 2) Conferences, performances, and other events map to the Event resource type

  describe 'Person contributor with single mapped role' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Data collector',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'compiler',
                  code: 'com',
                  uri: 'http://id.loc.gov/vocabulary/relators/com',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'DataCollector',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'compiler',
                  code: 'com',
                  uri: 'http://id.loc.gov/vocabulary/relators/com',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Person contributor with multiple roles, one maps to DataCite creator property' do
    # Stanford, Jane. Author and principal investigator.

    # NOTE: deduping of names to get multiple roles under a single contributor has been officially postponed by Amy and Arcadia

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'Principal investigator',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'research team head',
                  code: 'rth',
                  uri: 'http://id.loc.gov/vocabulary/relators/rth',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                },
                {
                  value: 'ProjectLeader',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'research team head',
                  code: 'rth',
                  uri: 'http://id.loc.gov/vocabulary/relators/rth',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/rth">rth</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/rth">research team head</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Organization contributor with single role' do
    # Stanford University. Host institution.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'Host institution',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'host institution',
                  code: 'his',
                  uri: 'http://id.loc.gov/vocabulary/relators/his',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'HostingInstitution',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'host institution',
                  code: 'his',
                  uri: 'http://id.loc.gov/vocabulary/relators/his',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Organization contributor with multiple roles' do
    # Stanford University. Sponsor and issuing body.

    # NOTE: deduping of names to get multiple roles under a single contributor has been officially postponed by Amy and Arcadia

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'Sponsor',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Sponsor',
                  source: {
                    value: 'DataCite contributor types'
                  }
                },
                {
                  value: 'Issuing body',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'issuing body',
                  code: 'isb',
                  uri: 'http://id.loc.gov/vocabulary/relators/isb',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Distributor',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'issuing body',
                  code: 'isb',
                  uri: 'http://id.loc.gov/vocabulary/relators/isb',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
            </role>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/isb">isb</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/isb">issuing body</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Conference as contributor' do
    # LDCX. Conference.
    xit 'not implemented: cocina form is missing on MODS to cocina roundtrip'

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'LDCX'
                }
              ],
              type: 'conference',
              status: 'primary',
              role: [
                {
                  value: 'Conference',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                }
              ]
            }
          ],
          form: [
            {
              value: 'Event',
              type: 'resource types',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'LDCX'
                }
              ],
              type: 'conference',
              status: 'primary'
            }
          ]
        }
      end

      # NOTE: conference does NOT get a role because 'conference' is a MODS name type
      let(:mods) do
        <<~XML
          <name type="conference" usage="primary">
            <namePart>LDCX</namePart>
          </name>
        XML
      end
    end
  end

  describe 'Event as contributor' do
    # San Francisco Symphony Concert. Event.

    xit 'not implemented: cocina form is missing on MODS to cocina roundtrip, type should be event'

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'San Francisco Symphony Concert'
                }
              ],
              type: 'event',
              status: 'primary',
              role: [
                {
                  value: 'Event',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                }
              ]
            }
          ],
          form: [
            {
              value: 'Event',
              type: 'resource types',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'San Francisco Symphony Concert'
                }
              ],
              type: 'organization', # this should be event
              status: 'primary',
              role: [
                {
                  value: 'Event'
                }
              ]
            }
          ]
        }
      end

      # NOTE: event does get a role because 'event' is NOT a MODS name type
      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>San Francisco Symphony Concert</namePart>
            <role>
              <roleTerm type="text">Event</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple contributors - person' do
    # Stanford, Jane. Author.
    # Stanford, Leland. Author.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Stanford, Leland</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple contributors - person and organization' do
    # Stanford, Jane. Author.
    # Stanford University. Sponsor.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'Sponsor',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Sponsor',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple person contributors + organization as author' do
    # Stanford, Jane. Author.
    # Stanford University. Author.
    # Stanford, Leland. Author.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Stanford, Leland</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple person contributors + organization as non-author' do
    # Stanford, Jane. Author.
    # Stanford University. Author.
    # Stanford, Leland. Author.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'Sponsor',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Sponsor',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland',
                  type: 'inverted full name'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'Author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford, Jane'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              role: [
                {
                  value: 'sponsor',
                  code: 'spn',
                  uri: 'http://id.loc.gov/vocabulary/relators/spn',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            },
            {
              name: [
                {
                  value: 'Stanford, Leland'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Stanford, Leland</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Funder' do
    # Stanford University. Funder.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'Funder',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'funder',
                  code: 'fnd',
                  uri: 'http://id.loc.gov/vocabulary/relators/fnd',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University'
                }
              ],
              type: 'organization',
              status: 'primary',
              role: [
                {
                  value: 'funder',
                  code: 'fnd',
                  uri: 'http://id.loc.gov/vocabulary/relators/fnd',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/fnd">fnd</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/fnd">funder</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Publisher and publication date entered by user' do
    # Stanford University Press. Publisher.
    # Publication date: Aug. 20, 2020

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  type: 'organization',
                  role: [
                    {
                      value: 'Publisher',
                      source: {
                        value: 'Stanford self-deposit contributor types'
                      }
                    },
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ]
                }
              ],
              date: [
                {
                  encoding: {
                    code: 'w3cdtf'
                  },
                  value: '2020-08-20',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  type: 'organization',
                  role: [
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ]
                }
              ],
              date: [
                {
                  encoding: {
                    code: 'w3cdtf'
                  },
                  value: '2020-08-20',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
            <dateIssued keyDate="yes" encoding="w3cdtf">2020-08-20</dateIssued>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publisher entered by user, no publication date' do
    # Stanford University Press. Publisher.

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  type: 'organization',
                  role: [
                    {
                      value: 'Publisher',
                      source: {
                        value: 'Stanford self-deposit contributor types'
                      }
                    },
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:roundtrip_cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  type: 'organization',
                  role: [
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end
end
