# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS contributor mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  # First entry in "Authors to include in citation" receives "status": "primary", which maps to "usage=primary" in MODS.

  describe 'Cited contributor with author role' do
    # Authors to include in citation
    ## Jane Stanford. Author.

    it_behaves_like 'cocina MODS mapping' do
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

    it_behaves_like 'cocina MODS mapping' do
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

    it_behaves_like 'cocina MODS mapping' do
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
                  value: 'department'
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
              <roleTerm type="text">department</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited and uncited authors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Leland Stanford. Contributing author.

    it_behaves_like 'cocina MODS mapping' do
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
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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
            <description>not included in citation</description>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">contributor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">ctb</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with uncited sponsoring organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Sponsor.

    it_behaves_like 'cocina MODS mapping' do
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
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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
            <description>not included in citation</description>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with Event role' do
    # Authors to include in citation
    ## San Francisco Symphony Concert. Event.

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
                  value: 'event'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        # Event is not valid MODS name type
        <<~XML
          <name usage="primary">
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

    it_behaves_like 'cocina MODS mapping' do
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
                }
              ]
            },
            {
              type: 'event',
              name: [
                {
                  value: 'San Francisco Symphony Concert'
                }
              ],
              role: [
                {
                  value: 'event'
                }
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/orm">organizer</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/orm">orm</roleTerm>
            </role>
          </name>
          <name>
            <namePart>San Francisco Symphony Concert</namePart>
            <description>not included in citation</description>
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
                  value: 'conference'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <name type="conference" usage="primary">
            <namePart>LDCX</namePart>
            <role>
              <roleTerm type="text">conference</roleTerm>
            </role>
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

    it_behaves_like 'cocina MODS mapping' do
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
                }
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spk">speaker</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spk">spk</roleTerm>
            </role>
          </name>
          <name type="conference">
            <namePart>LDCX</namePart>
            <description>not included in citation</description>
            <role>
              <roleTerm type="text">conference</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Cited contributor with Funder role' do
    # Authors to include in citation
    ## Stanford University. Funder.

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

    it_behaves_like 'cocina MODS mapping' do
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
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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
            <description>not included in citation</description>
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
    # Cited publisher goes into both contributor and event in cocina.

    it_behaves_like 'cocina MODS mapping' do
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
    # Uncited publisher goes into event only.

    it_behaves_like 'cocina MODS mapping' do
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

  describe 'Creator with ORCID' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## ORCID: 0000-0000-0000-0000
    it_behaves_like 'cocina MODS mapping' do
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

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <nameIdentifier type="orcid" typeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end

  describe 'Contributor with ORCID' do
    # Additional contributors
    ## Jane Stanford. Contributing author.
    ## ORCID: 0000-0000-0000-0000
    it_behaves_like 'cocina MODS mapping' do
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
                  uri: 'http://id.loc.gov/vocabulary/relators/ctb',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ],
              note: [
                {
                  type: 'citation status',
                  value: 'false'
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

      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart type="given">Jane</namePart>
            <namePart type="family">Stanford</namePart>
            <description>not included in citation</description>
            <nameIdentifier type="orcid" typeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">contributor</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/ctb">ctb</roleTerm>
            </role>
          </name>
        XML
      end
    end
  end
end
