# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS titleInfo <--> cocina mappings' do
  describe 'Basic title' do
    # How to ID: only subelement of titleInfo is title and no titleInfo type attribute
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Gaudy night</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Gaudy night'
            }
          ]
        }
      end
    end
  end

  describe 'Title with parts' do
    # How to ID: multiple subelements in titleInfo

    # NOTE: the nonsorting character count should be the number of characters in the nonsorting characters value plus 1
    # unless the nonsorting characters value ends with an apostrophe or a hyphen.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <nonSort>The</nonSort>
            <title>journal of stuff</title>
            <subTitle>a journal</subTitle>
            <partNumber>volume 5</partNumber>
            <partName>special issue</partName>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'The',
                  type: 'nonsorting characters'
                },
                {
                  value: 'journal of stuff',
                  type: 'main title'
                },
                {
                  value: 'a journal',
                  type: 'subtitle'
                },
                {
                  value: 'volume 5',
                  type: 'part number'
                },
                {
                  value: 'special issue',
                  type: 'part name'
                }
              ],
              note: [
                {
                  value: '4',
                  type: 'nonsorting character count'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Alternative title' do
    # How to ID: titleInfo type="alternative"
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Five red herrings</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Suspicious characters</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Five red herrings',
              status: 'primary'
            },
            {
              value: 'Suspicious characters',
              type: 'alternative'
            }
          ]
        }
      end
    end
  end

  describe 'Translated title' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary" lang="fre" altRepGroup="1">
            <title>Les misérables</title>
          </titleInfo>
          <titleInfo type="translated" lang="eng" altRepGroup="1">
            <title>The wretched</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Les misérables',
                  status: 'primary',
                  valueLanguage: {
                    code: 'fre',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: 'The wretched',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  },
                  type: 'translated'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Translated title (title is structuredValue)' do
    # How to ID: titleInfo type="translated"
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary" lang="fre" altRepGroup="1">
            <nonSort>Les</nonSort>
            <title>misérables</title>
          </titleInfo>
          <titleInfo type="translated" lang="eng" altRepGroup="1">
            <nonSort>The</nonSort>
            <title>wretched</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Les',
                      type: 'nonsorting characters'
                    },
                    {
                      value: 'misérables',
                      type: 'main title'
                    }
                  ],
                  note: [
                    {
                      value: '4',
                      type: 'nonsorting character count'
                    }
                  ],
                  status: 'primary',
                  valueLanguage: {
                    code: 'fre',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  structuredValue: [
                    {
                      value: 'The',
                      type: 'nonsorting characters'
                    },
                    {
                      value: 'wretched',
                      type: 'main title'
                    }
                  ],
                  note: [
                    {
                      value: '4',
                      type: 'nonsorting character count'
                    }
                  ],
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  },
                  type: 'translated'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Transliterated title (title is value)' do
    # How to ID: presence of titleInfo transliteration attribute (may need to manually review all records with a
    # titleInfo script element to catch additional instances)
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary" lang="rus" script="Cyrl" altRepGroup="1">
            <title>Война и миръ</title>
          </titleInfo>
          <titleInfo type="translated" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <title>Voĭna i mir</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Война и миръ',
                  status: 'primary',
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: 'Voĭna i mir',
                  valueLanguage: {
                    code: 'rus',
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
                  type: 'transliterated',
                  standard: {
                    value: 'ALA-LC Romanization Tables'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Transliterated title (not parallel)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo transliteration="ALA-LC Romanization Tables">
            <title>Mā baʻda 1930</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Mā baʻda 1930',
              type: 'transliterated',
              standard: {
                value: 'ALA-LC Romanization Tables'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title with authority and primary title' do
    # How to assign nameTitleGroup to MODS from cocina:
    #  Match value or structuredValue in uniform title note with type "associated name"
    #   to value or structuredValue in contributor name
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Hamlet</title>
          </titleInfo>
          <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="1">
            <title>Hamlet</title>
          </titleInfo>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="1">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Hamlet',
              status: 'primary'
            },
            {
              value: 'Hamlet',
              type: 'uniform',
              source: {
                uri: 'http://id.loc.gov/authorities/names/',
                code: 'naf'
              },
              uri: 'http://id.loc.gov/authorities/names/n80008522',
              note: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  uri: 'http://id.loc.gov/authorities/names/n78095332',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names/',
                    code: 'naf'
                  }
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

  describe 'Uniform title with multipart name and title' do
    # bb988jx6754
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Ballades, piano</title>
            <partNumber>no. 3, op. 47, A&#x266D; major</partNumber>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Chopin, Fr&#xE9;d&#xE9;ric</namePart>
            <namePart type="date">1810-1849</namePart>
            <role>
              <roleTerm type="text">composer</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Ballades, piano',
                  type: 'main title'
                },
                {
                  value: 'no. 3, op. 47, A♭ major',
                  type: 'part number'
                }
              ],
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Chopin, Frédéric',
                      type: 'name'
                    },
                    {
                      value: '1810-1849',
                      type: 'life dates'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Chopin, Frédéric',
                      type: 'name'
                    },
                    {
                      value: '1810-1849',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              status: 'primary',
              type: 'person',
              role: [
                {
                  value: 'composer'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name-title authority plus additional contributor not part of uniform title' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="1">
            <title>Hamlet</title>
          </titleInfo>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="1">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n78088956">
            <namePart>Marlowe, Christopher, 1564-1593</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Hamlet',
              type: 'uniform',
              uri: 'http://id.loc.gov/authorities/names/n80008522',
              source: {
                uri: 'http://id.loc.gov/authorities/names/',
                code: 'naf'
              },
              note: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  uri: 'http://id.loc.gov/authorities/names/n78095332',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names/',
                    code: 'naf'
                  }
                }
              ],
              type: 'person',
              status: 'primary'
            },
            {
              name: [
                {
                  value: 'Marlowe, Christopher, 1564-1593',
                  uri: 'http://id.loc.gov/authorities/names/n78088956',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names/',
                    code: 'naf'
                  }
                }
              ],
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title with repetition of author' do
    # Adapted from kd992vz2371
    # Ignore usage and nameTitleGroup when determining duplication; all subelements of name should be exact duplication
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Roman de la Rose. 1878</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Guillaume</namePart>
            <namePart type="termsOfAddress">de Lorris</namePart>
            <namePart type="date">active 1230</namePart>
          </name>
          <name type="personal">
            <namePart>Guillaume</namePart>
            <namePart type="termsOfAddress">de Lorris</namePart>
            <namePart type="date">active 1230</namePart>
          </name>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Roman de la Rose. 1878</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Guillaume</namePart>
            <namePart type="termsOfAddress">de Lorris</namePart>
            <namePart type="date">active 1230</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Roman de la Rose. 1878',
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Guillaume',
                      type: 'name'
                    },
                    {
                      value: 'de Lorris',
                      type: 'term of address'
                    },
                    {
                      value: 'active 1230',
                      type: 'activity dates'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Guillaume',
                      type: 'name'
                    },
                    {
                      value: 'de Lorris',
                      type: 'term of address'
                    },
                    {
                      value: 'active 1230',
                      type: 'activity dates'
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

      let(:warnings) do
        [
          Notification.new(msg: 'Duplicate name entry')
        ]
      end
    end
  end

  describe 'Uniform title with repetition of author plus role' do
    # Adapted from bf818dg3045
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Spring dreams</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Instrumental music. Selections</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Sheng, Bright</namePart>
            <namePart type="date">1955-</namePart>
          </name>
          <name type="personal">
            <namePart>Sheng, Bright</namePart>
            <namePart type="date">1955-</namePart>
            <role>
              <roleTerm authority="marcrelator" type="code">prf</roleTerm>
            </role>
          </name>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <titleInfo>
            <title>Spring dreams</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Instrumental music. Selections</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Sheng, Bright</namePart>
            <namePart type="date">1955-</namePart>
            <role>
              <roleTerm authority="marcrelator" type="code">prf</roleTerm>
            </role>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Spring dreams'
            },
            {
              value: 'Instrumental music. Selections',
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Sheng, Bright',
                      type: 'name'
                    },
                    {
                      value: '1955-',
                      type: 'life dates'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Sheng, Bright',
                      type: 'name'
                    },
                    {
                      value: '1955-',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  code: 'prf',
                  source: {
                    code: 'marcrelator'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'Duplicate name entry')] }
    end
  end

  describe 'Supplied title' do
    # How to ID: titleInfo supplied="yes"

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo supplied="yes">
            <title>"Because I could not stop for death"</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: '"Because I could not stop for death"',
              type: 'supplied'
            }
          ]
        }
      end
    end
  end

  describe 'Abbreviated title' do
    # How to ID: titleInfo type="abbreviated"
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Annual report of notifiable diseases</title>
          </titleInfo>
          <titleInfo type="abbreviated" authority="dnlm">
            <title>Annu. rep. notif. dis.</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Annual report of notifiable diseases',
              status: 'primary'
            },
            {
              value: 'Annu. rep. notif. dis.',
              type: 'abbreviated',
              source: {
                code: 'dnlm'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Parallel titles' do
    # How to ID: edge case requiring manual review of records with multiple titleInfo type="translated" instances

    xit 'not implemented: multiple type="translated" edge case' do
      let(:mods) do
        <<~XML
          <titleInfo type="translated" lang="ger" altRepGroup="1">
            <title>Berliner Mauer Kunst</title>
          </titleInfo>
          <titleInfo type="translated" lang="eng" altRepGroup="1">
            <title>Berlin's wall art</title>
          </titleInfo>
          <titleInfo type="translated" lang="spa" altRepGroup="1">
            <title>Arte en el muro de Berlin</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Berliner Mauer Kunst',
                  valueLanguage: {
                    code: 'ger',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: "Berlin's wall art",
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: 'Arte en el muro de Berlin',
                  valueLanguage: {
                    code: 'spa',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                }
              ],
              type: 'parallel'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple untyped titles without primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Symphony no. 6</title>
          </titleInfo>
          <titleInfo>
            <title>Pastoral symphony</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Symphony no. 6'
            },
            {
              value: 'Pastoral symphony'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple typed titles without primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Symphony no. 6</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Pastoral symphony</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Symphony no. 6'
            },
            {
              value: 'Pastoral symphony',
              type: 'alternative'
            }
          ]
        }
      end
    end
  end

  describe 'Title with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Unnatural death</title>
          </titleInfo>
          <titleInfo type="alternative" displayLabel="Original U.S. title">
            <title>The Dawson pedigree</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Unnatural death',
              status: 'primary'
            },
            {
              value: 'The Dawson pedigree',
              type: 'alternative',
              displayLabel: 'Original U.S. title'
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo xlink:href="http://title.org/title" />
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              valueAt: 'http://title.org/title'
            }
          ]
        }
      end
    end
  end

  describe 'Parallel uniform title in nameTitleGroup with parallel contributor NAME' do
    # adapted from cv621pf3709
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>Mishnah berurah. English</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
            <title>Mishnah berurah in Hebrew characters</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Israel Meir</namePart>
            <namePart type="termsOfAddress">ha-Kohen</namePart>
          </name>
          <name type="personal" altRepGroup="2" nameTitleGroup="2">
            <namePart>Israel Meir in Hebrew characters</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Mishnah berurah. English',
                  note: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir',
                          type: 'name'
                        },
                        {
                          value: 'ha-Kohen',
                          type: 'term of address'
                        }
                      ],
                      type: 'associated name'
                    }
                  ]
                },
                {
                  value: 'Mishnah berurah in Hebrew characters',
                  note: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir in Hebrew characters',
                          type: 'name'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ],
                      type: 'associated name'
                    }
                  ]
                }
              ],
              type: 'uniform'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir',
                          type: 'name'
                        },
                        {
                          value: 'ha-Kohen',
                          type: 'term of address'
                        }
                      ],
                      status: 'primary'
                    },
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir in Hebrew characters',
                          type: 'name'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ]
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
  end

  describe 'Uniform title with parallel name' do
    # cv621pf3709
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Correspondence respecting the affairs of Persia. Persian</title>
          </titleInfo>
          <name type="corporate" altRepGroup="1" nameTitleGroup="1" usage="primary">
            <namePart>Great Britain</namePart>
            <namePart>Foreign Office</namePart>
          </name>
          <name type="corporate" altRepGroup="1">
            <namePart>بريتانياى كبير</namePart>
            <namePart>وزارت خارجه</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Correspondence respecting the affairs of Persia. Persian',
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Great Britain'
                    },
                    {
                      value: 'Foreign Office'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      structuredValue: [
                        {
                          value: 'Great Britain'
                        },
                        {
                          value: 'Foreign Office'
                        }
                      ],
                      status: 'primary'
                    },
                    {
                      structuredValue: [
                        {
                          value: 'بريتانياى كبير'
                        },
                        {
                          value: 'وزارت خارجه'
                        }
                      ]
                    }
                  ]
                }
              ],
              status: 'primary',
              type: 'organization'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual uniform title' do
    # adapted from cv621pf3709
    # NOTE: clunky workaround for MARC data

    # How to assign nameTitleGroup to MODS from cocina:
    #  Match value or structuredValue in uniform title note with type "associated name"
    #   to value or structuredValue in contributor name
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Mishnah berurah</title>
            <subTitle>the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>Mishnah berurah. English and Hebrew</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Israel Meir</namePart>
            <namePart type="termsOfAddress">ha-Kohen</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <name type="personal" altRepGroup="2" script="" nameTitleGroup="2">
            <namePart>Israel Meir in Hebrew characters</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1" script="">
            <title>Mishnah berurah in Hebrew characters</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Mishnah berurah',
                  type: 'main title'
                },
                {
                  value: 'the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct',
                  type: 'subtitle'
                }
              ]
            },
            {
              parallelValue: [
                {
                  value: 'Mishnah berurah. English and Hebrew',
                  note: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir',
                          type: 'name'
                        },
                        {
                          value: 'ha-Kohen',
                          type: 'term of address'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ],
                      type: 'associated name'
                    }
                  ]
                },
                {
                  value: 'Mishnah berurah in Hebrew characters',
                  note: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir in Hebrew characters',
                          type: 'name'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ],
                      type: 'associated name'
                    }
                  ]
                }
              ],
              type: 'uniform'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir',
                          type: 'name'
                        },
                        {
                          value: 'ha-Kohen',
                          type: 'term of address'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ],
                      status: 'primary'
                    },
                    {
                      structuredValue: [
                        {
                          value: 'Israel Meir in Hebrew characters',
                          type: 'name'
                        },
                        {
                          value: '1838-1933',
                          type: 'life dates'
                        }
                      ]
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

      # Only change in round-trip mapping is dropping empty script attributes. In the round-trip 'name usage="primary"'
      # would come from the COCINA contributor property, not the title property, which is why it's not in the COCINA title mapping above, but still in the MODS below.
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo>
            <title>Mishnah berurah</title>
            <subTitle>the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>Mishnah berurah. English and Hebrew</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Israel Meir</namePart>
            <namePart type="termsOfAddress">ha-Kohen</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <name type="personal" altRepGroup="2" nameTitleGroup="2">
            <namePart>Israel Meir in Hebrew characters</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
            <title>Mishnah berurah in Hebrew characters</title>
          </titleInfo>
        XML
      end
    end
  end

  describe 'Uniform title with primary name without nameTitleGroup (MARC 7XX)' do
    # vb586bc9999
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform">
            <title>Æsop's fables. English. Babrius. Babrius</title>
          </titleInfo>
          <name type="personal" usage="primary">
            <namePart>Babrius</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Æsop\'s fables. English. Babrius. Babrius',
              type: 'uniform'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Babrius'
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

  describe 'Uniform title same as alternative title' do
    # dv507gh3920
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo altRepGroup="1">
            <title>Deyoḳno shel ha-oman ke-ish tsaʻir</title>
          </titleInfo>
          <titleInfo altRepGroup="1">
            <title>דיוקנו של האמן כאיש צעיר</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Portrait of the artist as a young man</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Portrait of the artist as a young man</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Joyce, James</namePart>
            <namePart type="date">1882-1941</namePart>
          </name>
          <name type="personal" altRepGroup="2">
            <namePart>ג׳ויס, ג׳יימס</namePart>
            <namePart type="date">1882־1941</namePart>
          </name>
        XML
      end

      # when there is a uniform title and (other type) with or without same value, then
      #  the nameTitleGroup in cocina->mods mapping should ONLY go to uniform title

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Deyoḳno shel ha-oman ke-ish tsaʻir'
                },
                {
                  value: 'דיוקנו של האמן כאיש צעיר'
                }
              ]
            },
            {
              value: 'Portrait of the artist as a young man',
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Joyce, James',
                      type: 'name'
                    },
                    {
                      value: '1882-1941',
                      type: 'life dates'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            },
            {
              value: 'Portrait of the artist as a young man',
              type: 'alternative'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      structuredValue: [
                        {
                          value: 'Joyce, James',
                          type: 'name'
                        },
                        {
                          value: '1882-1941',
                          type: 'life dates'
                        }
                      ],
                      # it's the primary name for the contributor
                      status: 'primary'
                    },
                    {
                      structuredValue: [
                        {
                          value: 'ג׳ויס, ג׳יימס',
                          type: 'name'
                        },
                        {
                          value: '1882־1941',
                          type: 'life dates'
                        }
                      ]
                    }
                  ]
                }
              ],
              type: 'person',
              # it's the primary contributor
              status: 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual uniform title with repeated name in multilingual alternative title' do
    # based on cs842gy7467
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>Sheʼerit Menaḥem</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
            <title>uniform title in Hebrew</title>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="3">
            <title>Sheʼerit Menaḥem</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Legs de Menahem</title>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="3">
            <title>alternative title in Hebrew</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Rubinstein, Samuel Jacob</namePart>
          </name>
          <name type="personal" altRepGroup="2" nameTitleGroup="2">
            <namePart>personal name in Hebrew</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Sheʼerit Menaḥem',
                  note: [
                    {
                      value: 'Rubinstein, Samuel Jacob',
                      type: 'associated name'
                    }
                  ]
                },
                {
                  value: 'uniform title in Hebrew',
                  note: [
                    {
                      value: 'personal name in Hebrew',
                      type: 'associated name'
                    }
                  ]
                }
              ],
              type: 'uniform'
            },
            {
              parallelValue: [
                {
                  value: 'Sheʼerit Menaḥem',
                  type: 'alternative'
                },
                {
                  value: 'alternative title in Hebrew',
                  type: 'alternative'
                }
              ]
            },
            {
              value: 'Legs de Menahem',
              type: 'alternative'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Rubinstein, Samuel Jacob',
                      status: 'primary'
                    },
                    {
                      value: 'personal name in Hebrew'
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

  describe 'Title with xml:space="preserve"' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <nonSort xml:space="preserve">A </nonSort>
            <title>broken journey</title>
            <subTitle>memoir of Mrs. Beatty, wife of Rev. William Beatty, Indian missionary</subTitle>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'A',
                  type: 'nonsorting characters'
                },
                {
                  value: 'broken journey',
                  type: 'main title'
                },
                {
                  value: 'memoir of Mrs. Beatty, wife of Rev. William Beatty, Indian missionary',
                  type: 'subtitle'
                }
              ],
              note: [
                {
                  value: '2',
                  type: 'nonsorting character count'
                }
              ]
            }
          ]
        }
      end

      # dropped xml:space="preserve" attribute on nonSort
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo>
            <nonSort>A </nonSort>
            <title>broken journey</title>
            <subTitle>memoir of Mrs. Beatty, wife of Rev. William Beatty, Indian missionary</subTitle>
          </titleInfo>
        XML
      end
    end
  end

  describe 'Uniform title with corporate author' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Laws, etc. (United States code service)</title>
          </titleInfo>
          <name usage="primary" type="corporate" nameTitleGroup="1">
            <namePart>United States</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Laws, etc. (United States code service)',
              type: 'uniform',
              note: [
                {
                  value: 'United States',
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'United States'
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

  describe 'Uniform title with multiple corporate authors' do
    # based on jp357bb8866
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Primary title</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Uniform title</title>
          </titleInfo>
          <name type="corporate" nameTitleGroup="1">
            <namePart>nameTitleGroup corp</namePart>
          </name>
          <name type="corporate">
            <namePart>2nd corp</namePart>
          </name>
        XML
      end

      # add status primary to nameTitleGroup name
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Primary title</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Uniform title</title>
          </titleInfo>
          <name type="corporate" nameTitleGroup="1" usage="primary">
            <namePart>nameTitleGroup corp</namePart>
          </name>
          <name type="corporate">
            <namePart>2nd corp</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Primary title',
              status: 'primary'
            },
            {
              value: 'Uniform title',
              type: 'uniform',
              note: [
                {
                  value: 'nameTitleGroup corp',
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'nameTitleGroup corp'
                }
              ],
              type: 'organization',
              status: 'primary'
            },
            {
              name: [
                {
                  value: '2nd corp'
                }
              ],
              type: 'organization'
            }
          ]
        }
      end
    end
  end

  # Data error handling

  describe 'Complex multilingual title' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah in Hebrew</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew</subTitle>
          </titleInfo>
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="2">
            <title>Shaʻare ha-ḳedushah</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Vital, Ḥayyim ben Joseph</namePart>
            <namePart type="date">1542 or 1543-1620</namePart>
          </name>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah in Hebrew</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew</subTitle>
          </titleInfo>
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Shaʻare ha-ḳedushah</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Vital, Ḥayyim ben Joseph</namePart>
            <namePart type="date">1542 or 1543-1620</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Sefer Shaʻare ha-ḳedushah in Hebrew',
                      type: 'main title'
                    },
                    {
                      value: 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew',
                      type: 'subtitle'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Sefer Shaʻare ha-ḳedushah',
                      type: 'main title'
                    },
                    {
                      value: 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo',
                      type: 'subtitle'
                    }
                  ]
                }
              ]
            },
            {
              value: 'Shaʻare ha-ḳedushah',
              type: 'uniform',
              note: [
                {
                  structuredValue: [
                    {
                      value: 'Vital, Ḥayyim ben Joseph',
                      type: 'name'
                    },
                    {
                      value: '1542 or 1543-1620',
                      type: 'life dates'
                    }
                  ],
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Vital, Ḥayyim ben Joseph',
                      type: 'name'
                    },
                    {
                      value: '1542 or 1543-1620',
                      type: 'life dates'
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
  end

  describe 'unmatching nameTitleGroup' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>English title</title>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="3" altRepGroup="1">
            <title>Esperanto title</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Vinsky Cat</namePart>
          </name>
          <name type="personal" altRepGroup="2" nameTitleGroup="4">
            <namePart>Wingnut Cat in Esperanto</namePart>
          </name>
        XML
      end

      # remove unmatched nameTitleGroup from titleInfo and name elements
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>English title</title>
          </titleInfo>
          <titleInfo type="uniform" altRepGroup="1">
            <title>Esperanto title</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Vinsky Cat</namePart>
          </name>
          <name type="personal" altRepGroup="2">
            <namePart>Wingnut Cat in Esperanto</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'English title',
                  note: [
                    {
                      value: 'Vinsky Cat',
                      type: 'associated name'
                    }
                  ]
                },
                {
                  value: 'Esperanto title'
                }
              ],
              type: 'uniform'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Vinsky Cat',
                      status: 'primary'
                    },
                    {
                      value: 'Wingnut Cat in Esperanto'
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

      let(:warnings) do
        [
          Notification.new(msg: "For title 'Esperanto title', no name matching nameTitleGroup 3.")
        ]
      end
    end
  end

  describe 'Multiple titles with primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Title 1</title>
          </titleInfo>
          <titleInfo usage="primary">
            <title>Title 2</title>
          </titleInfo>
        XML
      end

      let(:roundtrip_mods) do
        # Drop all instances of usage="primary" after first one
        <<~XML
          <titleInfo usage="primary">
            <title>Title 1</title>
          </titleInfo>
          <titleInfo>
            <title>Title 2</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Title 1',
              status: 'primary'
            },
            {
              value: 'Title 2'
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Multiple marked as primary', context: { type: 'title' })
        ]
      end
    end
  end

  describe 'Title with non-sorting characters with extra spaces' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <nonSort>The  </nonSort>
            <title>means to prosperity</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'The',
                  type: 'nonsorting characters'
                }, {
                  value: 'means to prosperity',
                  type: 'main title'
                }
              ],
              note: [
                {
                  value: '5',
                  type: 'nonsorting character count'
                }
              ],
              status: 'primary'
            }
          ]
        }
      end
    end
  end
end
