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
          "relatedResource": [
            {
              "title": [
                {
                  "value": 'Lymond chronicles'
                }
              ],
              "contributor": [
                {
                  "type": 'person',
                  "name": [
                    {
                      "value": 'Dunnett, Dorothy'
                    }
                  ]
                }
              ],
              "form": [
                {
                  "value": '6 vols.',
                  "type": 'extent'
                }
              ],
              "type": 'in series'
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
          "relatedResource": [
            {
              "title": [
                {
                  "value": 'Supplement'
                }
              ],
              "note": [
                {
                  "value": 'Additional data.',
                  "type": 'summary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related item without title' do
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
        "relatedResource": [
          {
            "access": {
              "url": [
                {
                  "value": 'https://www.example.com'
                }
              ]
            }
          }
        ]
      }
    end

    xit 'broken'
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
          "relatedResource": [
            {
              "title": [
                {
                  "value": 'Related item 1'
                }
              ]
            },
            {
              "title": [
                {
                  "value": 'Related item 2'
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
          "relatedResource": [
            {
              "title": [
                {
                  "value": 'Supplement'
                }
              ],
              "displayLabel": 'Additional data'
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
          "relatedResource": [
            {
              "type": 'has original version',
              "title": [
                {
                  "value": 'This item is related'
                }
              ],
              "adminMetadata": {
                "metadataStandard": [
                  {
                    "code": 'aacr2'
                  }
                ],
                "contributor": [
                  {
                    "name": [
                      {
                        "code": 'GPO',
                        "source": {
                          "code": 'marcorg'
                        }
                      }
                    ],
                    "type": 'organization',
                    "role": [
                      {
                        "value": 'original cataloging agency'
                      }
                    ]
                  }
                ],
                "event": [
                  {
                    "type": 'creation',
                    "date": [
                      {
                        "value": '780512',
                        "encoding": {
                          "code": 'marc'
                        }
                      }
                    ]
                  }
                ],
                "identifier": [
                  {
                    "value": '6766105',
                    "type": 'SUL catalog key'
                  },
                  {
                    "value": '3888071',
                    "type": 'OCLC'
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
          "relatedResource": [
            {
              "title": [
                {
                  "value": 'Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften'
                }
              ],
              "type": 'has other format',
              "displayLabel": 'Online version:'
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
          "relatedResource": [
            {
              "type": 'related to',
              "title": [
                {
                  "value": 'A related resource'
                }
              ],
              "note": [
                {
                  "type": 'other relation type',
                  "value": 'has part',
                  "uri": 'http://purl.org/dc/terms/hasPart',
                  "source": {
                    "value": 'DCMI'
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
    let(:mods) do
      <<~XML
        <relatedItem type="constituent">
          <titleInfo>
            <title>[Unidentified sextet] [incomplete]</title>
          </titleInfo>
          <relatedItem type="host" displaylabel="Concert title">
            <titleInfo>
              <title>Silver Saturday Blues</title>
            </titleInfo>
          </relatedItem>
        </relatedItem>
      XML
    end

    let(:cocina) do
      {
        "relatedResource": [
          {
            "type": 'has part',
            "title": [
              {
                "value": '[Unidentified sextet] [incomplete]'
              }
            ],
            "relatedResource": [
              {
                "type": 'part of',
                "displayLabel": 'Concert title',
                "title": [
                  {
                    "value": 'Silver Saturday Blues'
                  }
                ]
              }
            ]
          }
        ]
      }
    end

    xit 'not implemented'
  end
end
