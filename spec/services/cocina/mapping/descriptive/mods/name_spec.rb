# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS name <--> cocina mappings' do
  describe 'Personal name' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Name without type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              status: 'primary'
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'Missing or empty name type attribute')] }
    end
  end

  describe 'Corporate name' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Dorothy L. Sayers Society</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dorothy L. Sayers Society'
                }
              ],
              type: 'organization',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Family name' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="family" usage="primary">
            <namePart>James family</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'James family'
                }
              ],
              type: 'family',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Conference name' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="conference" usage="primary">
            <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Mystery Science Theater ConventioCon Expo Fest-o-rama'
                }
              ],
              type: 'conference',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Name with additional subelements' do
    # NOTE: name identifiers that are uris, for mods mapping purposes are 'value' rather than uri
    #  in identifier and nameIdentifier mods doesn't distinguish between a uri and other non-uri identifiers

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart type="termsOfAddress">Dr.</namePart>
            <namePart type="given">Terry</namePart>
            <namePart type="family">Castle</namePart>
            <namePart type="date">1953-</namePart>
            <affiliation>Stanford University</affiliation>
            <nameIdentifier type="wikidata">https://www.wikidata.org/wiki/Q7704207</nameIdentifier>
            <displayForm>Castle, Terry</displayForm>
            <description>Professor of English</description>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Dr.',
                      type: 'term of address'
                    },
                    {
                      value: 'Terry',
                      type: 'forename'
                    },
                    {
                      value: 'Castle',
                      type: 'surname'
                    },
                    {
                      value: '1953-',
                      type: 'life dates'
                    }
                  ]
                },
                {
                  value: 'Castle, Terry',
                  type: 'display'
                }
              ],
              status: 'primary',
              type: 'person',
              identifier: [
                {
                  value: 'https://www.wikidata.org/wiki/Q7704207',
                  type: 'Wikidata'
                }
              ],
              note: [
                {
                  value: 'Stanford University',
                  type: 'affiliation'
                },
                {
                  value: 'Professor of English',
                  type: 'description'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name with multiple affiliations' do
    # adapted from df430tk5419
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Schmedders, Karl</namePart>
            <affiliation>University of Zurich</affiliation>
            <affiliation>Swiss Finance Institute</affiliation>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Schmedders, Karl'
                }
              ],
              type: 'person',
              note: [
                {
                  value: 'University of Zurich',
                  type: 'affiliation'
                },
                {
                  value: 'Swiss Finance Institute',
                  type: 'affiliation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name with untyped nameIdentifier' do
    # NOTE: name identifiers that are uris, for mods mapping purposes are 'value' rather than uri
    #  in identifier and nameIdentifier mods doesn't distinguish between a uri and other non-uri identifiers

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Burnett, Michael W.</namePart>
            <nameIdentifier>https://orcid.org/0000-0001-5126-5568</nameIdentifier>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Burnett, Michael W.'
                }
              ],
              type: 'person',
              identifier: [
                {
                  value: 'https://orcid.org/0000-0001-5126-5568'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name with multiple untyped parts' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="corporate">
            <namePart>United States</namePart>
            <namePart>Office of Foreign Investment in the United States</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'United States',
                      type: 'name'
                    },
                    {
                      value: 'Office of Foreign Investment in the United States',
                      type: 'name'
                    }
                  ]
                }
              ],
              type: 'organization'
            }
          ]
        }
      end
    end
  end

  describe 'Name with ordinal' do
    xit('not implemented: ordinal type (determined from source data)')
    # Use "term of address" for "ordinal" if type of term cannot be determined from source data.

    let(:mods) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart type="given">Elizabeth</namePart>
          <namePart type="termsOfAddress">II</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                structuredValue: [
                  {
                    value: 'Elizabeth',
                    type: 'forename'
                  },
                  {
                    value: 'II',
                    type: 'ordinal'
                  }
                ]
              }
            ],
            type: 'person',
            status: 'primary'
          }
        ]
      }
    end
  end

  describe 'Name with role' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
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
    end
  end

  describe 'Role text only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
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
    end
  end

  describe 'Role code only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
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
    end
  end

  describe 'Role with valueURI as the only authority attribute' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  uri: 'http://id.loc.gov/vocabulary/relators/aut'
                }
              ]
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'Contributor role code is missing authority')] }
    end
  end

  describe 'Role with authority as the only authority attribute' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator">author</roleTerm>
              <roleTerm type="code" authority="marcrelator">aut</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author',
                  code: 'aut',
                  source: {
                    code: 'marcrelator'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Role without namePart value' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      let(:roundtrip_mods) { nil }

      let(:cocina) { {} }

      let(:warnings) do
        [
          Notification.new(msg: 'name/namePart missing value'),
          # NOTE: strictly speaking, the following warning isn't true ...
          Notification.new(msg: 'Missing name/namePart element')
        ]
      end
    end
  end

  describe 'Role attribute without roleTerm or namePart value' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
        XML
      end

      let(:roundtrip_mods) { nil }

      let(:cocina) { {} }

      let(:warnings) do
        [
          Notification.new(msg: 'name/namePart missing value'),
          # NOTE: strictly speaking, the following warning isn't true ...
          Notification.new(msg: 'Missing name/namePart element')
          # FIXME: we're not warning about missing roleTerm code/value?
        ]
      end
    end
  end

  describe 'Unauthorized role term only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Valid role code without authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name>
            <namePart>Selective Service System</namePart>
            <role>
              <roleTerm type="code">isb</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Selective Service System'
                }
              ],
              role: [
                {
                  code: 'isb'
                }
              ]
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Contributor role code is missing authority')
        ]
      end
    end
  end

  describe 'Name with multiple roles' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text">primary advisor</roleTerm>
            </role>
            <role>
              <roleTerm authority="marcrelator" type="code" authorityURI="http://id.loc.gov/vocabulary/relators/">ths</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'primary advisor'
                },
                {
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  },
                  code: 'ths'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Personal name with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n79046044">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
                  uri: 'http://id.loc.gov/authorities/names/n79046044',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'person',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Corporate name with authority' do
    # Example adapted from gq991tw6162
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n85809720">
            <namePart>Monterey Jazz Festival</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Monterey Jazz Festival',
                  uri: 'http://id.loc.gov/authorities/names/n85809720',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'organization',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Family name with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="family" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n000000">
            <namePart>Stanford family</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Stanford family',
                  uri: 'http://id.loc.gov/authorities/names/n000000',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'family',
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple names, one primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Bulgakov, Mikhail</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Burgin, Diana Lewis</namePart>
            <role>
              <roleTerm type="text">translator</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Bulgakov, Mikhail'
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'author'
                }
              ]
            },
            {
              name: [
                {
                  value: 'Burgin, Diana Lewis'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'translator'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple names, no roles' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Sarmiento, Domingo Faustino</namePart>
            <namePart type="date">1811-1888</namePart>
          </name>
          <name type="personal">
            <namePart>Rojas, Ricardo</namePart>
            <namePart type="date">1882-1957</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                structuredValue: [
                  {
                    value: 'Sarmiento, Domingo Faustino',
                    type: 'name'
                  },
                  {
                    type: 'life dates',
                    value: '1811-1888'
                  }
                ]
              ],
              type: 'person',
              status: 'primary'
            },
            {
              name: [
                structuredValue: [
                  {
                    value: 'Rojas, Ricardo',
                    type: 'name'
                  },
                  {
                    type: 'life dates',
                    value: '1882-1957'
                  }
                ]
              ],
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple names, no primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Gaiman, Neil</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Pratchett, Terry</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Gaiman, Neil'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'author'
                }
              ]
            },
            {
              name: [
                {
                  value: 'Pratchett, Terry'
                }
              ],
              type: 'person',
              role: [
                {
                  value: 'author'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Single name, no primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Tey, Josephine</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Tey, Josephine'
                }
              ],
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple names with transliteration (name as value)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name usage="primary" type="personal" script="Cyrl" altRepGroup="1">
            <namePart>Булгаков, Михаил Афанасьевич</namePart>
          </name>
          <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Bulgakov, Mikhail Afanasʹevich</namePart>
          </name>
          <name type="personal" script="Cyrl" altRepGroup="2">
            <namePart>Олеша, Юрий Карлович</namePart>
          </name>
          <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="2">
            <namePart>Olesha, I︠U︡riĭ Karlovich</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Булгаков, Михаил Афанасьевич',
                      status: 'primary',
                      valueLanguage: {
                        valueScript: {
                          code: 'Cyrl',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: 'Bulgakov, Mikhail Afanasʹevich',
                      valueLanguage: {
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      },
                      type: 'transliteration',
                      standard: {
                        value: 'ALA-LC Romanization Tables'
                      }
                    }
                  ],
                  type: 'person',
                  status: 'primary'
                }
              ]
            },
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Олеша, Юрий Карлович',
                      valueLanguage: {
                        valueScript: {
                          code: 'Cyrl',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: 'Olesha, I︠U︡riĭ Karlovich',
                      valueLanguage: {
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      },
                      type: 'transliteration',
                      standard: {
                        value: 'ALA-LC Romanization Tables'
                      }
                    }
                  ],
                  type: 'person'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Transliterated name with parts (name as structuredValue)' do
    xit('not mapped: for reference only.')

    # This example is for reference only - doesn't need to be mapped.  Splitting the name isn't implemented
    let(:mods) do
      <<~XML
        <name usage="primary" type="personal" script="Cyrl" altRepGroup="0">
          <namePart>Булгаков, Михаил Афанасьевич</namePart>
        </name>
        <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
          <namePart>Bulgakov, Mikhail Afanasʹevich</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                parallelValue: [
                  {
                    structuredValue: [
                      {
                        value: 'Михаил Афанасьевич',
                        type: 'forename'
                      },
                      {
                        value: 'Булгаков',
                        type: 'surname'
                      }
                    ],
                    status: 'primary',
                    valueLanguage: {
                      valueScript: {
                        code: 'Cyrl',
                        source: {
                          value: 'ISO 15924'
                        }
                      }
                    }
                  },
                  {
                    structuredValue: [
                      {
                        value: 'Mikhail Afanasʹevich',
                        type: 'forename'
                      },
                      {
                        value: 'Bulgakov',
                        type: 'surname'
                      }
                    ],
                    valueLanguage: {
                      valueScript: {
                        code: 'Latn',
                        source: {
                          value: 'ISO 15924'
                        }
                      }
                    },
                    type: 'transliteration',
                    standard: {
                      value: 'ALA-LC Romanization Tables'
                    }
                  }
                ]
              }
            ],
            type: 'person',
            status: 'primary'
          }
        ]
      }
    end
  end

  describe 'Transliterated name with role' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
            <namePart>レアメタル資源再生技術研究会</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
            </role>
          </name>
          <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      status: 'primary',
                      valueLanguage: {
                        code: 'jpn',
                        source: {
                          code: 'iso639-2b'
                        },
                        valueScript: {
                          code: 'Jpan',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      },
                      value: 'レアメタル資源再生技術研究会'
                    },
                    {
                      valueLanguage: {
                        code: 'jpn',
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
                      type: 'transliteration',
                      standard: {
                        value: 'ALA-LC Romanization Tables'
                      },
                      value: 'Rea Metaru Shigen Saisei Gijutsu Kenkyūkai'
                    }
                  ],
                  type: 'organization',
                  status: 'primary'
                }
              ],
              role: [
                {
                  value: 'creator',
                  code: 'cre',
                  uri: 'http://id.loc.gov/vocabulary/relators/cre',
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
    end
  end

  describe 'Name with et al.' do
    xit 'not implemented: etal for contributor'

    let(:mods) do
      <<~XML
        <name type="personal">
          <namePart>Frydman, Judith</namePart>
        </name>
        <name>
          <etal/>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Frydman, Judith'
              }
            ],
            type: 'person'
          },
          {
            type: 'unspeciied others'
          }
        ]
      }
    end
  end

  describe 'Name with display label' do
    xit 'not implemented: displayLabel for contributor'

    let(:mods) do
      <<~XML
        <name type="personal" displayLabel="Pseudonym">
          <namePart>Westmacott, Mary</namePart>
        </name>
      XML
    end

    # OK to omit type: pseudonym in MODS mapping.
    let(:roundtrip_mods) do
      <<~XML
        <name type="personal" displayLabel="Pseudonym">
          <namePart>Westmacott, Mary</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Westmacott, Mary',
                type: 'pseudonym',
                displayLabel: 'Pseudonym'
              }
            ],
            type: 'person'
          }
        ]
      }
    end
  end

  describe 'Name with valueURI only (authority URI)' do
    xit 'not implemented: mapping to contributor with valueURI only'

    let(:mods) do
      <<~XML
        <name valueURI="https://id.loc.gov/authorities/names/123">
          <affiliation>Stanford</affiliation>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                uri: 'https://id.loc.gov/authorities/names/123'
              },
              note: [
                {
                  value: 'Stanford',
                  type: 'affiliation'
                }
              ]
            ]
          }
        ]
      }
    end
  end

  describe 'Name with nameIdentifier only (RWO URI)' do
    xit 'not implemented: mapping to contributor with nameIdentifier only'

    let(:mods) do
      <<~XML
        <name>
          <nameIdentifier type="orcid">0000-0000-0000</nameIdentifier>
          <role>
            <roleTerm type="code" authority="marcrelator">aut</roleTerm>
          </role>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: '0000-0000-0000',
                type: 'ORCID'
              }
            ],
            role: [
              {
                code: 'aut',
                source: {
                  code: 'marcrelator'
                }
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Name with external link to value only' do
    it_behaves_like 'MODS cocina mapping' do
      # Note this handling of xlink:href is ONLY for when it is the only attribute and there are no children.
      let(:mods) do
        <<~XML
          <name xlink:href="http://name.org/name" />
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  valueAt: 'http://name.org/name'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Full name with additional subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Sarmiento, Domingo Faustino</namePart>
            <namePart type="date">1811-1888</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Sarmiento, Domingo Faustino',
                      type: 'name'
                    },
                    {
                      value: '1811-1888',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              status: 'primary',
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Name with active date - year' do
    xit 'not implemented: type activity dates'

    # If date starts with "active," use type "activity dates" and drop "active" from date value
    let(:mods) do
      <<~XML
        <name type="personal">
          <namePart>Yao, Zongyi</namePart>
          <namePart type="date">Active 1618</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Yao, Zongyi',
                type: 'name'
              },
              {
                value: '1618',
                type: 'activity dates'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Name with active date - century' do
    xit 'not implemented: type activity dates'

    # If date starts with "active," use type "activity dates" and drop "active" from date value
    let(:mods) do
      <<~XML
        <name type="personal">
          <namePart>Inoue, Kaian</namePart>
          <namePart type="date">Active 18th century</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Inoue, Kaian',
                type: 'name'
              },
              {
                value: '18th century',
                type: 'activity dates'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Name with approximate date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Lassus, Rudolph de</namePart>
            <namePart type="date">approximately 1563-1625</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Lassus, Rudolph de',
                      type: 'name'
                    },
                    {
                      value: 'approximately 1563-1625',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Name with language' do
    it_behaves_like 'MODS cocina mapping' do
      # adapted from cp049zn0898
      let(:mods) do
        <<~XML
          <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
            <namePart>Rea Metaru Shigen Saisei Gijutsu Kenkyūkai in Japanese characters</namePart>
          </name>
          <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Rea Metaru Shigen Saisei Gijutsu Kenkyūkai</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Rea Metaru Shigen Saisei Gijutsu Kenkyūkai in Japanese characters',
                      status: 'primary',
                      valueLanguage: {
                        code: 'jpn',
                        source: {
                          code: 'iso639-2b'
                        },
                        valueScript: {
                          code: 'Jpan',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: 'Rea Metaru Shigen Saisei Gijutsu Kenkyūkai',
                      type: 'transliteration',
                      valueLanguage: {
                        code: 'jpn',
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
                      standard: {
                        value: 'ALA-LC Romanization Tables'
                      }
                    }
                  ],
                  type: 'organization',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'Multiple names with primary and matching altRepGroup' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <name usage="primary" altRepGroup="1" type="personal">
          <namePart>Name v1</namePart>
        </name>
        <name usage="primary" altRepGroup="1" type="personal">
          <namePart>Name v2</namePart>
        </name>
      XML
    end

    let(:roundtrip_mods) do
      # Drop all instances of usage="primary" after first one
      <<~XML
        <name usage="primary" altRepGroup="1" type="personal">
          <namePart>Name v1</namePart>
        </name>
        <name altRepGroup="1" type="personal">
          <namePart>Name v2</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                parallelValue: [
                  {
                    value: 'Name v1',
                    status: 'primary'
                  },
                  {
                    value: 'Name v2'
                  }
                ]
              }
            ],
            status: 'primary',
            type: 'person'
          }
        ]
      }
    end

    let(:warnings) do
      [
        Notification.new(msg: 'Multiple names marked as primary')
      ]
    end
  end

  describe 'Multiple names with primary and no matching altRepGroup' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <name usage="primary" type="personal">
          <namePart>Name 1</namePart>
        </name>
        <name usage="primary" type="personal">
          <namePart>Name 2</namePart>
        </name>
      XML
    end

    let(:roundtrip_mods) do
      # Drop all instances of usage="primary" after first one
      <<~XML
        <name usage="primary" type="personal">
          <namePart>Name 1</namePart>
        </name>
        <name type="personal">
          <namePart>Name 2</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Name 1'
              }
            ],
            status: 'primary',
            type: 'person'
          },
          {
            name: [
              value: 'Name 2'
            ],
            type: 'person'
          }
        ]
      }
    end

    let(:warnings) do
      [
        Notification.new(msg: 'Multiple contributors marked as primary')
      ]
    end
  end

  describe 'Duplicate names' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          contributor: [
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ],
              type: 'person'
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Duplicate name entry')
        ]
      end
    end
  end
end
