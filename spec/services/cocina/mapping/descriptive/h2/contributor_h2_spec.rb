# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS contributor mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  #
  # First entry in "Authors to include in citation" receives "status": "primary", which maps to "usage=primary" in MODS. This attribute indicates that
  # a) Systems should use this name as sort key when sorting by author
  # b) MARC mappings should put this name in the 100 field as main author
  # c) Other applications where a single name must be chosen for a purpose (such as constructing a citation using "et al.") should use this name.
  #
  # DataCite role mappings vary due to its different structure. Most roles map to DataCite contributor types, with the following exceptions:
  # 1) Authors included in citation map to the Creator property, which does not have roles
  # 2) Conferences, performances, and other events map to the Event resource type

  describe 'Cited contributor and organization' do
    # Authors to include in citation
    ## Stanford, Jane. Author.
    ## Stanford University. Sponsor.

    xit 'updated mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
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

  describe 'Multiple cited authors including organization' do
    # Authors to include in citation
    ## Stanford, Jane. Author.
    ## Stanford University. Author.
    ## Stanford, Leland. Author.

    xit 'updated mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Leland',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Leland',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
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
            <namePart type="given">Leland</namePart>
            <namePart type="family"Stanford</namePart>
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

  describe 'Multiple cited authors + organization cited in other role' do
    # Authors to include in citation
    ## Stanford, Jane. Author.
    ## Stanford University. Sponsor.
    ## Stanford, Leland. Author.

    xit 'updated mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Leland',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Jane',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
                  structuredValue: [
                    {
                      value: 'Leland',
                      type: 'forename'
                    },
                    {
                      value: 'Stanford',
                      type: 'surname'
                    }
                  ]
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
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
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
            <namePart type="given">Leland</namePart>
            <namePart type="family">Stanford</namePart>
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
end
