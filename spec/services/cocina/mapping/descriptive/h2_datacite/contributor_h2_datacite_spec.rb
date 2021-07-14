# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite contributor mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  # Authors to include in citation > cocina role type: DataCite role, value: Creator > DataCite creator element
  # Additional contributors > cocina role type: DataCite role, value: [mapped role] > DataCite contributor element with contributorType [mapped role]
  # EXCEPTION:
  # H2 funder role > cocina role type: DataCite role, value: Funder > DataCite fundingReference element

  describe 'Cited contributor with author role' do
    # Authors to include in citation
    ## Jane Stanford. Author.

    xit 'not implemented' do
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
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Multiple cited contributors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## Leland Stanford. Author.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
            <creator>
              <creatorName nameType="Personal">Stanford, Leland</creatorName>
              <givenName>Leland</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Cited contributor with cited organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    ## Stanford University. Sponsor.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
            <creator>
              <creatorName nameType="Organizational">Stanford University</creatorName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Cited organization' do
    # Authors to include in citation
    ## Stanford University. Host institution.

    xit 'not implemented' do
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
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University</creatorName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Multiple cited organizations' do
    # Authors to include in citation
    ## Stanford University. Host institution.
    ## Department of English. Department.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                  value: 'department'
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University</creatorName>
            </creator>
            <creator>
              <creatorName nameType="Organizational">Department of English</creatorName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Cited and uncited authors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Leland Stanford. Contributing author.
    # Add contributor role to names in Additional contributors section.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                },
                {
                  value: 'Other',
                  type: 'DataCite role',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Personal">Stanford, Leland</contributorName>
              <givenName>Leland</givenName>
              <familyName>Stanford</familyName>
            </contributor>
          </contributors>
        XML
      end
    end
  end

  describe 'Cited contributor with uncited sponsoring organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Sponsor.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                },
                {
                  value: 'Sponsor',
                  type: 'DataCite role',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <contributors>
            <contributor contributorType="Sponsor">
              <contributorName nameType="Organizational">Stanford University</contributorName>
            </contributor>
          </contributors>
        XML
      end
    end
  end

  describe 'Cited contributor with Event role' do
    # Authors to include in citation
    ## San Francisco Symphony Concert. Event.

    xit 'not implemented' do
      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'San Francisco Symphony Concert'
                }
              ],
              status: 'primary',
              role: [
                {
                  value: 'event'
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">San Francisco Symphony Concert</creatorName>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Event role' do
    # Authors to include in citation
    ## Jane Stanford. Event organizer.
    # Additional contributors
    ## San Francisco Symphony Concert. Event.

    xit 'not implemented' do
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
                  type: 'DataCite role'
                }
              ]
            },
            {
              name: [
                {
                  value: 'San Francisco Symphony Concert'
                }
              ],
              role: [
                {
                  value: 'event'
                },
                {
                  value: 'Other',
                  type: 'DataCite role',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Organizational">San Francisco Symphony Concert</contributorName>
            </contributor>
          </contributors>
        XML
      end
    end
  end

  describe 'Cited contributor with Conference role' do
    # Authors to include in citation
    ## LDCX. Conference.

    xit 'not implemented' do
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
                  value: 'conference'
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">LDCX</creatorName>
            </creator>
          </creator>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Conference role' do
    # Authors to include in citation
    ## Jane Stanford. Speaker.
    # Additional contributors
    ## LDCX. Conference.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
              role: [
                {
                  value: 'conference'
                },
                {
                  value: 'Other',
                  type: 'DataCite role',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Organizational">LDCX</contributorName>
            </contributor>
          </contributors>
        XML
      end
    end
  end

  describe 'Cited contributor with Funder role' do
    # Authors to include in citation
    ## Stanford University. Funder.

    xit 'not implemented' do
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
                  type: 'DataCite role'
                },
                {
                  value: 'Funder',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University</creatorName>
            </creator>
          </creators>
          <fundingReferences>
            <fundingReference>
              <funderName>Stanford University</funderName>
            </fundingReference>
          <fundingReferences>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Funder role' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Funder.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                },
                {
                  value: 'Funder',
                  type: 'DataCite role'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        # maps to fundingReferences if DataCite Funder
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <fundingReferences>
            <fundingReference>
              <funderName>Stanford University</funderName>
            </fundingReference>
          <fundingReferences>
        XML
      end
    end
  end

  describe 'Cited contributor with Publisher role' do
    # Authors to include in citation
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

    xit 'not implemented' do
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
                  role: [
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
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University Press</creatorName>
            </creator>
          </creators>
          <publisher>Stanford Digital Repository</publisher>
        XML
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Publisher role' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

    xit 'not implemented' do
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
                  type: 'DataCite role'
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
                  role: [
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
                      value: 'Distributor',
                      type: 'DataCite role',
                      source: {
                        value: 'DataCite contributor types'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
            </creator>
          </creators>
          <contributors>
            <contributor contributorType="Distributor">
              <contributorName nameType="Organizational">Stanford University Press</contributorName>
            </contributor>
          </contributors>
          <publisher>Stanford Digital Repository</publisher>
        XML
      end
    end
  end

  describe 'Creator with ORCID' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## ORCID: 0000-0000-0000-0000
    xit 'not implemented' do
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
                  type: 'DataCite role'
                }
              ],
              identifier: [
                {
                  value: '0000-0000-0000-0000',
                  type: 'ORCID',
                  source: {
                    uri: 'https://orcid.org'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Stanford, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
              <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
            </creator>
          </creators>
        XML
      end
    end
  end

  describe 'Contributor with ORCID' do
    # Additional contributors
    ## Jane Stanford. Contributing author.
    ## ORCID: 0000-0000-0000-0000
    xit 'not implemented' do
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
                  value: 'contributor',
                  code: 'ctb',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  value: 'Other',
                  type: 'DataCite role',
                  source: {
                    value: 'DataCite contributor types'
                  }
                }
              ],
              identifier: [
                {
                  value: '0000-0000-0000-0000',
                  type: 'ORCID',
                  source: {
                    uri: 'https://orcid.org'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Personal">Stanford, Jane</contributorName>
              <givenName>Jane</givenName>
              <familyName>Stanford</familyName>
              <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
            </contributor>
          </contributors>
        XML
      end
    end
  end
end
