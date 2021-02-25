# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings TEST' do
  context 'with eventType' do
    describe 'matches date type' do
      xit 'not implemented' do
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
      xit 'not implemented' do
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

    describe 'multiple date types' do
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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

  context 'without eventType' do
    describe 'single date type' do
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
      xit 'not implemented' do
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
    xit 'not implemented' do
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
end
