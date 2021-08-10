# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings TEST' do
  context 'with eventType' do
    describe 'matches date type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <dateIssued>1990</dateIssued>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '1990',
                    type: 'publication'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'does not match date type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <copyrightDate>1990</copyrightDate>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '1990',
                    type: 'copyright'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'empty copyright data' do
      # From kt699vd2377
      # An empty copyrightDate is bad data. The name is included to test the xpaths that check for presence of
      # valueURI/xlink:href in originInfo. (Previously, they were looking anywhere in the document.)
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <name type="corporate" valueURI="http://id.loc.gov/authorities/names/n2005043549">
              <namePart>Automobile Club of Southern California</namePart>
            </name>
            <originInfo eventType="copyright notice">
              <copyrightDate />
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <name type="corporate" valueURI="http://id.loc.gov/authorities/names/n2005043549">
              <namePart>Automobile Club of Southern California</namePart>
            </name>
          XML
        end

        let(:cocina) do
          {
            contributor: [
              {
                name: [
                  {
                    value: 'Automobile Club of Southern California',
                    uri: 'http://id.loc.gov/authorities/names/n2005043549'
                  }
                ],
                type: 'organization'
              }
            ]
          }
        end
      end
    end

    describe 'multiple date types' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <dateIssued>1930</dateIssued>
              <copyrightDate>1929</copyrightDate>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '1930',
                    type: 'publication'
                  },
                  {
                    value: '1929',
                    type: 'copyright'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'one date type, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <dateIssued>2000</dateIssued>
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '2000',
                    type: 'publication'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'multiple date types, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <dateIssued>2000</dateIssued>
              <copyrightDate>1930</copyrightDate>
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '2000',
                    type: 'publication'
                  },
                  {
                    value: '1930',
                    type: 'copyright'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'no date element, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateOther with same type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="acquisition">
              <dateOther type="acquisition">1990</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'acquisition',
                date: [
                  {
                    value: '1990',
                    type: 'acquisition'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateOther with different type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="acquisition">
              <dateOther type="deaccession">1990</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'acquisition',
                date: [
                  {
                    value: '1990',
                    type: 'deaccession'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateOther without type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="acquisition">
              <dateOther>1990</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'acquisition',
                date: [
                  {
                    value: '1990'
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end

  context 'with no eventType' do
    describe 'single date type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateCreated>1990</dateCreated>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1990',
                    type: 'creation'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'multiple date types' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateIssued>1990</dateIssued>
              <copyrightDate>1930</copyrightDate>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1990',
                    type: 'publication'
                  },
                  {
                    value: '1930',
                    type: 'copyright'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'one date type, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateIssued>2000</dateIssued>
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '2000',
                    type: 'publication'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'multiple date types, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateIssued>2000</dateIssued>
              <copyrightDate>1930</copyrightDate>
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '2000',
                    type: 'publication'
                  },
                  {
                    value: '1930',
                    type: 'copyright'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'no date element, other subelements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <publisher>Persephone Books</publisher>
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                contributor: [
                  {
                    name: [
                      {
                        value: 'Persephone Books'
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
                      }
                    ],
                    type: 'organization'
                  }
                ],
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateOther with type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="acquisition">1990</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1990',
                    type: 'acquisition'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateOther without type' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther>1990</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1990'
                  }
                ]
              }
            ]
          }
        end

        let(:warnings) { [Notification.new(msg: 'Undetermined date type')] }
      end
    end
  end

  describe 'copyright notice eventType' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="copyright notice">
             <copyrightDate>©2018</copyrightDate>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'copyright notice',
              note: [
                {
                  value: '©2018',
                  type: 'copyright statement'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'legacy MARC2MODS 264 mappings' do
    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction sometimes used eventType with diff values.
    #   The next 4 tests are for the 4 specific eventType values that should be corrected.
    describe 'producer eventType' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="producer">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="production">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'production',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'publisher eventType' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="publisher">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="publication">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'distributor eventType' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="distributor">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="distribution">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'distribution',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'manufacturer eventType' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="manufacturer">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="manufacture">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'manufacture',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction used displayLabel as a stopgap measure.
    #   The next 4 tests are for the 4 specific displayLabel values that should be converted to eventType.
    describe 'producer displayLabel' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo displayLabel="producer">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="production">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'production',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'publisher displayLabel' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo displayLabel="publisher">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="publication">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'distributor displayLabel' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo displayLabel="distributor">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="distribution">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'distribution',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'manufacturer displayLabel' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo displayLabel="manufacturer">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
            <originInfo eventType="manufacture">
              <place>
                <placeTerm type="text">London</placeTerm>
              </place>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                type: 'manufacture',
                location: [
                  {
                    value: 'London'
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end
end
