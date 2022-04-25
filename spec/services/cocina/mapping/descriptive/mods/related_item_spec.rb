# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS relatedItem <--> cocina mappings' do
  describe 'Related item with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="series">
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <physicalDescription>
              <extent>6 vols.</extent>
            </physicalDescription>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Lymond chronicles'
                }
              ],
              contributor: [
                {
                  type: 'person',
                  name: [
                    {
                      value: 'Dunnett, Dorothy'
                    }
                  ]
                }
              ],
              form: [
                {
                  value: '6 vols.',
                  type: 'extent'
                }
              ],
              type: 'in series'
            }

          ]
        }
      end
    end
  end

  describe 'Related item without type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <titleInfo>
              <title>Supplement</title>
            </titleInfo>
            <abstract>Additional data.</abstract>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Supplement'
                }
              ],
              note: [
                {
                  value: 'Additional data.',
                  type: 'abstract'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related item without title' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <location>
              <url>https://www.example.com</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              access: {
                url: [
                  {
                    value: 'https://www.example.com'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end

  describe 'Related item with PURL' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <location>
              <url>http://purl.stanford.edu/ng599nr9959</url>
            </location>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <relatedItem>
            <location>
              <url usage="primary display">https://purl.stanford.edu/ng599nr9959</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              purl: 'https://purl.stanford.edu/ng599nr9959'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple related items' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <titleInfo>
              <title>Related item 1</title>
            </titleInfo>
          </relatedItem>
          <relatedItem>
            <titleInfo>
              <title>Related item 2</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Related item 1'
                }
              ]
            },
            {
              title: [
                {
                  value: 'Related item 2'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related item with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem displayLabel="Additional data">
            <titleInfo>
              <title>Supplement</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Supplement'
                }
              ],
              displayLabel: 'Additional data'
            }
          ]
        }
      end
    end
  end

  describe 'Related item with recordInfo' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="original">
            <titleInfo>
              <title>This item is related</title>
            </titleInfo>
            <recordInfo>
              <descriptionStandard>aacr2</descriptionStandard>
              <recordContentSource authority="marcorg">GPO</recordContentSource>
              <recordCreationDate encoding="marc">780512</recordCreationDate>
              <recordIdentifier source="SUL catalog key">6766105</recordIdentifier>
              <recordIdentifier source="oclc">3888071</recordIdentifier>
            </recordInfo>
          </relatedItem>
        XML
      end

      # capitalized OCLC
      let(:roundtrip_mods) do
        <<~XML
          <relatedItem type="original">
            <titleInfo>
              <title>This item is related</title>
            </titleInfo>
            <recordInfo>
              <descriptionStandard>aacr2</descriptionStandard>
              <recordContentSource authority="marcorg">GPO</recordContentSource>
              <recordCreationDate encoding="marc">780512</recordCreationDate>
              <recordIdentifier source="SUL catalog key">6766105</recordIdentifier>
              <recordIdentifier source="OCLC">3888071</recordIdentifier>
            </recordInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'has original version',
              title: [
                {
                  value: 'This item is related'
                }
              ],
              adminMetadata: {
                metadataStandard: [
                  {
                    code: 'aacr2'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        code: 'GPO',
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
                        value: '780512',
                        encoding: {
                          code: 'marc'
                        }
                      }
                    ]
                  }
                ],
                identifier: [
                  {
                    value: '6766105',
                    type: 'SUL catalog key'
                  },
                  {
                    value: '3888071',
                    type: 'OCLC'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end

  describe 'Related item with otherType - invalid' do
    # ERROR - otherType attribute can't be used if type is present
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="otherFormat" otherType="Online version:" displayLabel="Online version:">
            <titleInfo>
              <title>Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <relatedItem type="otherFormat" displayLabel="Online version:">
            <titleInfo>
              <title>Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften'
                }
              ],
              type: 'has other format',
              displayLabel: 'Online version:'
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Related resource has type and otherType')
        ]
      end
    end
  end

  describe 'Related item with otherType - valid' do
    # otherType can't map to 'type' because a) it's not necessarily in the type vocabulary mapping and b) it has
    # associated authority attributes that can't be represented in 'type'
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem otherType="has part" otherTypeURI="http://purl.org/dc/terms/hasPart" otherTypeAuth="DCMI">
            <titleInfo>
              <title>A related resource</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'related to',
              title: [
                {
                  value: 'A related resource'
                }
              ],
              note: [
                {
                  type: 'other relation type',
                  value: 'has part',
                  uri: 'http://purl.org/dc/terms/hasPart',
                  source: {
                    value: 'DCMI'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related item with related item' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo>
              <title>[Unidentified sextet] [incomplete]</title>
            </titleInfo>
            <relatedItem type="host" displayLabel="Concert title">
              <titleInfo>
                <title>Silver Saturday Blues</title>
              </titleInfo>
            </relatedItem>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'has part',
              title: [
                {
                  value: '[Unidentified sextet] [incomplete]'
                }
              ],
              relatedResource: [
                {
                  type: 'part of',
                  displayLabel: 'Concert title',
                  title: [
                    {
                      value: 'Silver Saturday Blues'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related item with untyped name' do
    # Certain related items mapped from MARC don't indicate name type in source data
    # Do not warn for untyped names in relatedItem
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="otherFormat" displayLabel="Online version:">
            <titleInfo>
              <title>Hearing 1., VA's compliance with year 2000 requirements</title>
            </titleInfo>
            <identifier>(OCoLC)808865049</identifier>
            <name>
              <namePart>United States. Congress. House. Committee on Veterans' Affairs. Subcommittee on Oversight and Investigations</namePart>
            </name>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'has other format',
              displayLabel: 'Online version:',
              title: [
                {
                  value: 'Hearing 1., VA\'s compliance with year 2000 requirements'
                }
              ],
              identifier: [
                {
                  value: '(OCoLC)808865049'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'United States. Congress. House. Committee on Veterans\' Affairs. Subcommittee on Oversight and Investigations'
                    }
                  ]
                }
              ]
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
          <relatedItem xlink:href="http://relateditem.org/relateditem" />
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              valueAt: 'http://relateditem.org/relateditem'
            }
          ]
        }
      end
    end
  end

  describe 'Empty related item - A' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <titleInfo>
              <title/>
            </titleInfo>
            <location>
              <url/>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) { {} }

      let(:roundtrip_mods) { '' }

      let(:warnings) do
        [
          Notification.new(msg: 'Empty title node')
        ]
      end
    end
  end

  describe 'Empty related item - B' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="original"/>
        XML
      end

      let(:cocina) { {} }

      let(:roundtrip_mods) { '' }
    end
  end

  describe 'Empty related item - C' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo>
              <title/>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) { {} }

      let(:roundtrip_mods) { '' }

      let(:warnings) do
        [
          Notification.new(msg: 'Empty title node')
        ]
      end
    end
  end

  describe 'related item with nameTitleGroup with simple name' do
    # based on fk884nj8194
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Carte géologique de la Tunisie</title>
          </titleInfo>
          <relatedItem>
            <titleInfo nameTitleGroup="1">
              <title>Annales des mines et de la géologie</title>
            </titleInfo>
            <name type="corporate" nameTitleGroup="1">
              <namePart>Tunisia.</namePart>
            </name>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Carte géologique de la Tunisie'
            }
          ],
          relatedResource: [
            {
              title: [
                {
                  value: 'Annales des mines et de la géologie',
                  note: [
                    {
                      type: 'associated name',
                      value: 'Tunisia.'
                    }
                  ]
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    {
                      value: 'Tunisia.'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'related item with nameTitleGroup with multipart name' do
    # based on fk884nj8194
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>Carte géologique de la Tunisie</title>
          </titleInfo>
          <relatedItem>
            <titleInfo nameTitleGroup="1">
              <title>Annales des mines et de la géologie</title>
            </titleInfo>
            <name type="corporate" nameTitleGroup="1">
              <namePart>Tunisia.</namePart>
              <namePart>Direction des travaux publics.</namePart>
            </name>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Carte géologique de la Tunisie'
            }
          ],
          relatedResource: [
            {
              title: [
                {
                  value: 'Annales des mines et de la géologie',
                  note: [
                    {
                      type: 'associated name',
                      structuredValue: [
                        {
                          value: 'Tunisia.'
                        },
                        {
                          value: 'Direction des travaux publics.'
                        }
                      ]
                    }
                  ]
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    structuredValue: [
                      {
                        value: 'Tunisia.'
                      },
                      {
                        value: 'Direction des travaux publics.'
                      }
                    ]
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'related item with nameTitleGroup and title with nameTitleGroup' do
    # based on qj452rj6647
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <nonSort xml:space="preserve">The </nonSort>
            <title>ballad of Baby Doe</title>
            <subTitle>libretto</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Ballad of Baby Doe</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Latouche, John</namePart>
            <namePart type="date">1914-1956</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <relatedItem displayLabel="Libretto for (work):">
            <titleInfo nameTitleGroup="1">
              <title>Ballad of Baby Doe</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="1">
              <namePart>Moore, Douglas,</namePart>
              <namePart type="date">1893-1969</namePart>
            </name>
          </relatedItem>
        XML
      end

      # different nameTitleGroup number in the relatedItem
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo>
            <nonSort>The </nonSort>
            <title>ballad of Baby Doe</title>
            <subTitle>libretto</subTitle>
          </titleInfo>
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Ballad of Baby Doe</title>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Latouche, John</namePart>
            <namePart type="date">1914-1956</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <relatedItem displayLabel="Libretto for (work):">
            <titleInfo nameTitleGroup="2">
              <title>Ballad of Baby Doe</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="2">
              <namePart>Moore, Douglas,</namePart>
              <namePart type="date">1893-1969</namePart>
            </name>
          </relatedItem>
        XML
      end

      # The change in nameTitleGroup ids means this won't roundtrip to the normalized MODS, hence skipping.
      let(:skip_normalization) { true }

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
                  value: 'ballad of Baby Doe',
                  type: 'main title'
                },
                {
                  value: 'libretto',
                  type: 'subtitle'
                }
              ],
              note: [
                {
                  type: 'nonsorting character count',
                  value: '4'
                }
              ]
            },
            {
              value: 'Ballad of Baby Doe',
              type: 'uniform',
              note: [
                {
                  type: 'associated name',
                  structuredValue: [
                    {
                      value: 'Latouche, John',
                      type: 'name'
                    },
                    {
                      value: '1914-1956',
                      type: 'life dates'
                    }
                  ]
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
                      value: 'Latouche, John',
                      type: 'name'
                    },
                    {
                      value: '1914-1956',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                value: 'author'
              ]
            }
          ],
          relatedResource: [
            {
              title: [
                {
                  value: 'Ballad of Baby Doe',
                  note: [
                    {
                      type: 'associated name',
                      structuredValue: [
                        {
                          value: 'Moore, Douglas,',
                          type: 'name'
                        },
                        {
                          value: '1893-1969',
                          type: 'life dates'
                        }
                      ]
                    }
                  ]
                }
              ],
              contributor: [
                {
                  type: 'person',
                  name: [
                    structuredValue: [
                      {
                        value: 'Moore, Douglas,',
                        type: 'name'
                      },
                      {
                        value: '1893-1969',
                        type: 'life dates'
                      }
                    ]
                  ]
                }
              ],
              displayLabel: 'Libretto for (work):'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple related items with nameTitleGroups' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <titleInfo>
            <title>A title</title>
          </titleInfo>
          <relatedItem type="constituent">
            <titleInfo type="uniform" nameTitleGroup="1">
              <title>Contradizione</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart>Bacewicz, Grayna.</namePart>
            </name>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo type="uniform" nameTitleGroup="1">
              <title>Concerto in one movement, marimba, orchestra</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart>Diemer, Emma Lou.</namePart>
            </name>
          </relatedItem>
        XML
      end

      # two distinct nameTitleGroups
      let(:roundtrip_mods) do
        <<~XML
          <titleInfo>
            <title>A title</title>
          </titleInfo>
          <relatedItem type="constituent">
            <titleInfo type="uniform" nameTitleGroup="1">
              <title>Contradizione</title>
            </titleInfo>
            <name usage="primary" type="personal" nameTitleGroup="1">
              <namePart>Bacewicz, Grayna.</namePart>
            </name>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo type="uniform" nameTitleGroup="2">
              <title>Concerto in one movement, marimba, orchestra</title>
            </titleInfo>
            <name usage="primary" type="personal" nameTitleGroup="2">
              <namePart>Diemer, Emma Lou.</namePart>
            </name>
          </relatedItem>
        XML
      end

      # The goal of this test is to have different relatedItems originally with the same nameTitleGroup ids.
      # However, this won't roundtrip to the normalized MODS, hence skipping.
      let(:skip_normalization) { true }

      let(:cocina) do
        {
          title: [
            {
              value: 'A title'
            }
          ],
          relatedResource: [
            {
              title: [
                {
                  value: 'Contradizione',
                  type: 'uniform',
                  note: [
                    {
                      type: 'associated name',
                      value: 'Bacewicz, Grayna.'
                    }
                  ]
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Bacewicz, Grayna.'
                    }
                  ],
                  type: 'person',
                  status: 'primary'
                }
              ],
              type: 'has part'
            },
            {
              title: [
                {
                  value: 'Concerto in one movement, marimba, orchestra',
                  type: 'uniform',
                  note: [
                    {
                      type: 'associated name',
                      value: 'Diemer, Emma Lou.'
                    }
                  ]
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Diemer, Emma Lou.'
                    }
                  ],
                  type: 'person',
                  status: 'primary'
                }
              ],
              type: 'has part'
            }
          ]
        }
      end
    end
  end

  describe 'Related item with empty number' do
    # Adapted from ck234jp5954
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Koeman B and H 2</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number/>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Koeman B and H 2</title>
            </titleInfo>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'referenced by',
              title: [
                {
                  value: 'Koeman B and H 2'
                }
              ]
            }
          ]
        }
      end
    end
  end
end
