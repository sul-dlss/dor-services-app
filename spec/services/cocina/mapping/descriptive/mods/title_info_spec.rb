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
          "title": [
            {
              "value": 'Gaudy night'
            }
          ]
        }
      end
    end
  end

  describe 'Title with parts' do
    # How to ID: multiple subelements in titleInfo
    # Note: the nonsorting character count should be the number of characters in the nonsorting characters value plus 1
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
          "title": [
            {
              "structuredValue": [
                {
                  "value": 'The',
                  "type": 'nonsorting characters'
                },
                {
                  "value": 'journal of stuff',
                  "type": 'main title'
                },
                {
                  "value": 'a journal',
                  "type": 'subtitle'
                },
                {
                  "value": 'volume 5',
                  "type": 'part number'
                },
                {
                  "value": 'special issue',
                  "type": 'part name'
                }
              ],
              "note": [
                {
                  "value": '4',
                  "type": 'nonsorting character count'
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
          "title": [
            {
              "value": 'Five red herrings',
              "status": 'primary'
            },
            {
              "value": 'Suspicious characters',
              "type": 'alternative'
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
          "title": [
            {
              "parallelValue": [
                {
                  "structuredValue": [
                    {
                      "value": 'Les',
                      "type": 'nonsorting characters'
                    },
                    {
                      "value": 'misérables',
                      "type": 'main title'
                    }
                  ],
                  "note": [
                    {
                      "value": '4',
                      "type": 'nonsorting character count'
                    }
                  ],
                  "status": 'primary',
                  "valueLanguage": {
                    "code": 'fre',
                    "source": {
                      "code": 'iso639-2b'
                    }
                  }
                },
                {
                  "structuredValue": [
                    {
                      "value": 'The',
                      "type": 'nonsorting characters'
                    },
                    {
                      "value": 'wretched',
                      "type": 'main title'
                    }
                  ],
                  "note": [
                    {
                      "value": '4',
                      "type": 'nonsorting character count'
                    }
                  ],
                  "type": 'translated',
                  "valueLanguage": {
                    "code": 'eng',
                    "source": {
                      "code": 'iso639-2b'
                    }
                  }
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
          "title": [
            {
              "parallelValue": [
                {
                  "value": 'Война и миръ',
                  "status": 'primary',
                  "valueLanguage": {
                    "code": 'rus',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Cyrl',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  }
                },
                {
                  "value": 'Voĭna i mir',
                  "valueLanguage": {
                    "code": 'rus',
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
                  "type": 'transliterated',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title with authority' do
    # How to ID: titleInfo type="uniform"
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Hamlet</title>
          </titleInfo>
          <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="1">
            <title>Hamlet</title>
          </titleInfo>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="1">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          "title": [
            {
              "value": 'Hamlet',
              "status": 'primary'
            },
            {
              "structuredValue": [
                {
                  "value": 'Hamlet',
                  "type": 'title'
                },
                {
                  "value": 'Shakespeare, William, 1564-1616',
                  "type": 'name',
                  "uri": 'http://id.loc.gov/authorities/names/n78095332',
                  "source": {
                    "uri": 'http://id.loc.gov/authorities/names/',
                    "code": 'naf'
                  }
                }
              ],
              "type": 'uniform',
              "source": {
                "uri": 'http://id.loc.gov/authorities/names/',
                "code": 'naf'
              },
              "uri": 'http://id.loc.gov/authorities/names/n80008522'
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "value": 'Shakespeare, William, 1564-1616',
                  "type": 'name',
                  "uri": 'http://id.loc.gov/authorities/names/n78095332',
                  "source": {
                    "uri": 'http://id.loc.gov/authorities/names/',
                    "code": 'naf'
                  }
                }
              ],
              "status": 'primary',
              "type": 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title with multiple namePart subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Princesse jaune. Vocal score</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart type="family">Saint-Sa&#xEB;ns</namePart>
            <namePart type="given">Camille</namePart>
            <namePart type="date">1835-1921</namePart>
          </name>
        XML
      end

      let(:cocina) do
        {
          "title": [
            {
              "structuredValue": [
                {
                  "value": 'Princesse jaune. Vocal score',
                  "type": 'title'
                },
                {
                  "structuredValue": [
                    {
                      "value": 'Saint-Saëns',
                      "type": 'surname'
                    },
                    {
                      "value": 'Camille',
                      "type": 'forename'
                    },
                    {
                      "value": '1835-1921',
                      "type": 'life dates'
                    }
                  ],
                  "type": 'name'
                }
              ],
              "type": 'uniform'
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "structuredValue": [
                    {
                      "value": 'Saint-Saëns',
                      "type": 'surname'
                    },
                    {
                      "value": 'Camille',
                      "type": 'forename'
                    },
                    {
                      "value": '1835-1921',
                      "type": 'life dates'
                    }
                  ]
                }
              ],
              "type": 'person',
              "status": 'primary'
            }
          ]
        }
      end
    end
  end

  describe 'Name-title authority plus additional contributor not part of uniform title' do
    let(:mods) do
      <<~XML
        <titleInfo usage="primary">
          <title>Hamlet</title>
        </titleInfo>
        <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="0">
          <title>Hamlet</title>
        </titleInfo>
        <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="0">
          <namePart>Shakespeare, William, 1564-1616</namePart>
        </name>
        <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78088956">
          <namePart>Marlowe, Christopher, 1564-1593</namePart>
        </name>
      XML
    end

    let(:cocina) do
      {
        "title": [
          {
            "value": 'Hamlet',
            "status": 'primary'
          },
          {
            "structuredValue": [
              {
                "value": 'Hamlet',
                "type": 'title'
              },
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'name',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              }
            ],
            "type": 'uniform',
            "uri": 'http://id.loc.gov/authorities/names/n80008522',
            "source": {
              "uri": 'http://id.loc.gov/authorities/names/',
              "code": 'naf'
            }
          }
        ],
        "contributor": [
          {
            "name": [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "status": 'primary',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              }
            ]
          },
          {
            "name": [
              {
                "value": 'Marlowe, Christopher, 1564-1593',
                "type": 'person',
                "status": 'primary',
                "uri": 'http://id.loc.gov/authorities/names/n78088956',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              }
            ]
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Supplied title' do
    # How to ID: titleInfo supplied="yes"
    let(:mods) do
      <<~XML
        <titleInfo supplied="yes">
          <title>"Because I could not stop for death"</title>
        </titleInfo>
      XML
    end

    let(:cocina) do
      {
        "title": [
          {
            "value": '"Because I could not stop for death"',
            "type": 'supplied'
          }
        ]
      }
    end

    xit 'not implemented'
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
          "title": [
            {
              "value": 'Annual report of notifiable diseases',
              "status": 'primary'
            },
            {
              "value": 'Annu. rep. notif. dis.',
              "type": 'abbreviated',
              "source": {
                "code": 'dnlm'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Parallel titles' do
    # How to ID: edge case requiring manual review of records with multiple titleInfo type="translated" instances
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
        "title": [
          {
            "parallelValue": [
              {
                "value": 'Berliner Mauer Kunst',
                "valueLanguage": {
                  "code": 'ger',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "value": "Berlin's wall art",
                "valueLanguage": {
                  "code": 'eng',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "value": 'Arte en el muro de Berlin',
                "valueLanguage": {
                  "code": 'spa',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              }
            ],
            "type": 'parallel'
          }
        ]
      }
    end

    xit 'not implemented'
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
          "title": [
            {
              "value": 'Symphony no. 6'
            },
            {
              "value": 'Pastoral symphony'
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
          "title": [
            {
              "value": 'Symphony no. 6'
            },
            {
              "value": 'Pastoral symphony',
              "type": 'alternative'
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
          "title": [
            {
              "value": 'Unnatural death',
              "status": 'primary'
            },
            {
              "value": 'The Dawson pedigree',
              "type": 'alternative',
              "displayLabel": 'Original U.S. title'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual uniform title' do
    it_behaves_like 'MODS cocina mapping' do
      # Both <name> elements have usage="primary" so "status": "primary" maps to contributor rather than name.
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
          "title": [
            {
              "parallelValue": [
                {
                  "structuredValue": [
                    {
                      "value": 'Mishnah berurah. English and Hebrew',
                      "type": 'title'
                    },
                    {
                      "structuredValue": [
                        {
                          "value": 'Israel Meir',
                          "type": 'name'
                        },
                        {
                          "value": 'ha-Kohen',
                          "type": 'term of address'
                        },
                        {
                          "value": '1838-1933',
                          "type": 'life dates'
                        }
                      ],
                      "type": 'name'
                    }
                  ]
                },
                {
                  "structuredValue": [
                    {
                      "structuredValue": [
                        {
                          "value": 'Israel Meir in Hebrew characters',
                          "type": 'name'
                        },
                        {
                          "value": '1838-1933',
                          "type": 'life dates'
                        }
                      ],
                      "type": 'name'
                    },
                    {
                      "value": 'Mishnah berurah in Hebrew characters',
                      "type": 'title'
                    }
                  ]
                }
              ],
              "type": 'uniform'
            },
            {
              "structuredValue": [
                {
                  "value": 'Mishnah berurah',
                  "type": 'main title'
                },
                {
                  "value": 'the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct',
                  "type": 'subtitle'
                }
              ]
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "parallelValue": [
                    {
                      "structuredValue": [
                        {
                          "value": 'Israel Meir',
                          "type": 'name'
                        },
                        {
                          "value": 'ha-Kohen',
                          "type": 'term of address'
                        },
                        {
                          "value": '1838-1933',
                          "type": 'life dates'
                        }
                      ],
                      "status": 'primary'
                    },
                    {
                      "structuredValue": [
                        {
                          "value": 'Israel Meir in Hebrew characters',
                          "type": 'name'
                        },
                        {
                          "value": '1838-1933',
                          "type": 'life dates'
                        }
                      ]
                    }
                  ],
                  "type": 'person',
                  "status": 'primary'
                }
              ]
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
          "title": [
            {
              "structuredValue": [
                {
                  "value": 'A',
                  "type": 'nonsorting characters'
                },
                {
                  "value": 'broken journey',
                  "type": 'main title'
                },
                {
                  "value": 'memoir of Mrs. Beatty, wife of Rev. William Beatty, Indian missionary',
                  "type": 'subtitle'
                }
              ],
              "note": [
                {
                  "value": '2',
                  "type": 'nonsorting character count'
                }
              ]
            }
          ]
        }
      end

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
end
