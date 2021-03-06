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
              <url usage="primary display">http://purl.stanford.edu/ng599nr9959</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              purl: 'http://purl.stanford.edu/ng599nr9959',
              access: {

                digitalRepository: [
                  {
                    value: 'Stanford Digital Repository'
                  }
                ]
              }
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

  describe 'Multiple related items with nameTitleGroups' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo nameTitleGroup="1">
              <title>Contradizione</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="1">
              <namePart>Bacewicz, Grayna.</namePart>
            </name>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo nameTitleGroup="1">
              <title>Concerto in one movement, marimba, orchestra</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="1">
              <namePart>Diemer, Emma Lou.</namePart>
            </name>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo nameTitleGroup="1">
              <title>Contradizione</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="1">
              <namePart>Bacewicz, Grayna.</namePart>
            </name>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo nameTitleGroup="2">
              <title>Concerto in one movement, marimba, orchestra</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="2">
              <namePart>Diemer, Emma Lou.</namePart>
            </name>
          </relatedItem>
        XML
      end

      # The goal of this test is to have different relatedItems with the same nameTitleGroup ids.
      # However, this won't roundtrip to the normalized MODS, hence skipping.
      let(:skip_normalization) { true }

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  structuredValue: [
                    {
                      type: 'title',
                      value: 'Contradizione'
                    },
                    {
                      value: 'Bacewicz, Grayna.',
                      type: 'name'
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
                  type: 'person'
                }
              ],
              type: 'has part'
            },
            {
              title: [
                {
                  structuredValue: [
                    {
                      type: 'title',
                      value: 'Concerto in one movement, marimba, orchestra'
                    },
                    {
                      value: 'Diemer, Emma Lou.',
                      type: 'name'
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
                  type: 'person'
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
