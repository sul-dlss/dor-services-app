# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS contributor mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  # DataCite role mapping notes:
  # 1) Mappings to DataCite contributor roles in spreadsheet are for names in
  # "Additional contributors" only
  # 2) "Authors included in citation" map to the Creator property, which does not have
  # an associated role
  # 3) Conferences, performances, and other events map to the Event resource type
  #
  # First entry in "Authors to include in citation" receives "status": "primary",
  # which maps to "usage=primary" in MODS.

  describe 'Cited contributor' do
    # Authors to include in citation
    ## Jane Stanford. Author.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple cited contributors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## Leland Stanford. Author.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart type="given">Leland</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with cited organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    ## Stanford University. Sponsor.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'compiler',
                  code: 'com',
                  uri: 'http://id.loc.gov/vocabulary/relators/com',
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited organization' do
    # Authors to include in citation
    ## Stanford University. Host institution.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Multiple cited organizations' do
    # Authors to include in citation
    ## Stanford University. Host institution.
    ## Department of English. Department.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'Department of English'
                }
              ],
              type: 'organization',
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
              role: [
                {
                  value: 'Department',
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
            },
            {
              name: [
                {
                  value: 'Department of English'
                }
              ],
              type: 'organization',
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Department of English</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
            </role>
          <name>
        XML
      end
    end
  end

  describe 'Cited and uncited contributors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Leland Stanford. Contributing author.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              note: [
                {
                  value: 'exclude from citation',
                  type: 'citation status'
                }
              ],
              role: [
                {
                  value: 'Contributing author',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'contributor',
                  code: 'ctb',
                  uri: 'http://id.loc.gov/vocabulary/relators/ctb',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Other',
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
                  value: 'contributor',
                  code: 'ctb',
                  uri: 'http://id.loc.gov/vocabulary/relators/ctb',
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart type="given">Leland</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">contributor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">ctb</roleTerm>
            </role>
          <name>
        XML
      end
    end
  end

  describe 'Cited contributor with uncited organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Sponsor.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              note: [
                {
                  value: 'exclude from citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'compiler',
                  code: 'com',
                  uri: 'http://id.loc.gov/vocabulary/relators/com',
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            </role>
          <name>
        XML
      end
    end
  end

  # Special role handling

  describe 'Cited contributor with Event role' do
    # Authors to include in citation
    ## San Francisco Symphony Concert. Event.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              type: 'event',
              status: 'primary'
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
              <roleTerm type="text">event</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Event role' do
    # Authors to include in citation
    ## Jane Stanford. Event organizer.
    # Additional contributors
    ## San Francisco Symphony Concert. Event.
    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
              role: [
                {
                  value: 'Event organizer',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'organizer',
                  code: 'orm',
                  uri: 'http://id.loc.gov/vocabulary/relators/orm',
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
                  value: 'San Francisco Symphony Concert'
                }
              ],
              type: 'event',
              note: [
                {
                  value: 'exclude from citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'organizer',
                  code: 'orm',
                  uri: 'http://id.loc.gov/vocabulary/relators/orm',
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
                  value: 'San Francisco Symphony Concert'
                }
              ],
              type: 'event'
            }
          ]
        }
      end

      # NOTE: event does get a role because 'event' is NOT a MODS name type
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/orm">organizer</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/orm">orm</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>San Francisco Symphony Concert</namePart>
            <role>
              <roleTerm type="text">event</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with Conference role' do
    # Authors to include in citation
    ## LDCX. Conference.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
              role: [
                {
                  value: 'Conference',
                  source: {
                    value: 'Stanford self-deposit contributor types'
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

  describe 'Cited contributor and uncited contributor with Conference role' do
    # Authors to include in citation
    ## Jane Stanford. Speaker.
    # Additional contributors
    ## LDCX. Conference.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
              role: [
                {
                  value: 'Speaker',
                  source: {
                    value: 'Stanford self-deposit contributor types'
                  }
                },
                {
                  value: 'speaker',
                  code: 'spk',
                  uri: 'http://id.loc.gov/vocabulary/relators/spk',
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
                  value: 'LDCX'
                }
              ],
              type: 'conference',
              status: 'primary',
              note: [
                {
                  value: 'exclude from citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'speaker',
                  code: 'spk',
                  uri: 'http://id.loc.gov/vocabulary/relators/spk',
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
                  value: 'LDCX'
                }
              ],
              type: 'conference'
            }
          ]
        }
      end

      # NOTE: conference does NOT get a role because 'conference' is a MODS name type
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spk">speaker</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spk">spk</roleTerm>
            </role>
          </name>
          <name type="conference">
            <namePart>LDCX</namePart>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with Funder role' do
    # Authors to include in citation
    ## Stanford University. Funder.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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

  describe 'Cited contributor and uncited contributor with Funder role' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Funder.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
              note: [
                {
                  value: 'exclude from citation',
                  type: 'citation status'
                }
              ],
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
                  value: 'compiler',
                  code: 'com',
                  uri: 'http://id.loc.gov/vocabulary/relators/com',
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
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
            </role>
          </name>
          <name type="corporate">
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

  describe 'Cited contributor with Publisher role' do
    # Authors to include in citation
    ## Stanford University Press. Publisher.

    xit 'unimplemented mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University Press'
                }
              ],
              type: 'organization',
              status: 'primary',
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            }
          ],
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

      let(:roundtrip_cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University Press'
                }
              ],
              type: 'organization',
              status: 'primary',
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
          <name type="corporate" usage="primary">
            <namePart>Stanford University Press</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pbl">publisher</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pbl">pbl</roleTerm>
            </role>
          </name>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Publisher role' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Stanford University Press. Publisher.

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
          ],
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
            }
          ],
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
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Cited contributor with Publisher role and publication date' do
    # Authors to include in citation
    ## Stanford University Press. Publisher.
    # Publication date
    ## 2020-02-02

    xit 'unimplemented mapping' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford University Press'
                }
              ],
              type: 'organization',
              status: 'primary',
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
                },
                {
                  value: 'Creator',
                  source: {
                    value: 'DataCite properties'
                  }
                }
              ]
            }
          ],
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
                  value: '2020-02-02',
                  status: 'primary'
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
                  value: 'Stanford University Press'
                }
              ],
              type: 'organization',
              status: 'primary',
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
                  value: '2020-02-02',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University Press</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pbl">publisher</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pbl">pbl</roleTerm>
            </role>
          </name>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
            <dateIssued keyDate="yes" encoding="w3cdtf">2020-02-02</dateIssued>
          </originInfo>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Publisher role and publication date' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Stanford University Press. Publisher.
    # Publication date
    ## 2020-02-02

    xit 'unimplemented mapping' do
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
              note: [
                {
                  value: 'include in citation',
                  type: 'citation status'
                }
              ],
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
          ],
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
                  value: '2020-02-02',
                  status: 'primary'
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
            }
          ],
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
                  value: '2020-02-02',
                  status: 'primary'
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
            <dateIssued keyDate="yes" encoding="w3cdtf">2020-02-02</dateIssued>
          </originInfo>
        XML
      end
    end
  end
end
