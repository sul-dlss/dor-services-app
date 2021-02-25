# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings' do
  describe 'Single dateCreated' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated>1980</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1980',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Single dateIssued (with encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued encoding="w3cdtf">1928</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1928',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Single copyrightDate' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
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

  describe 'Single dateCaptured (ISO 8601 encoding, keyDate)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '20131012231249',
                  type: 'capture',
                  encoding: {
                    code: 'iso8601'
                  },
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Single dateOther' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateOther type="Islamic">1441 AH</dateOther>
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
                  value: '1441 AH',
                  type: 'Islamic'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'dateOther in Gregorian calendar' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="acquisition" displayLabel="Acquisition date">
            <dateOther encoding="w3cdtf">1992</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'acquisition',
              displayLabel: 'Acquisition date',
              date: [
                {
                  value: '1992',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1920',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1925',
                      type: 'end'
                    }
                  ],
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Approximate date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated qualifier="approximate">1940</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1940',
                  type: 'creation',
                  qualifier: 'approximate'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Approximate date range' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
            <dateCreated point="end" qualifier="approximate">1945</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1940',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1945',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  qualifier: 'approximate'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range, approximate start date only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
            <dateCreated point="end">1945</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1940',
                      type: 'start',
                      status: 'primary',
                      qualifier: 'approximate'
                    },
                    {
                      value: '1945',
                      type: 'end'
                    }
                  ],
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range, approximate end date only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start">1940</dateCreated>
            <dateCreated point="end" qualifier="approximate">1945</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1940',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1945',
                      type: 'end',
                      qualifier: 'approximate'
                    }
                  ],
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Inferred date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated qualifier="inferred">1940</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1940',
                  type: 'creation',
                  qualifier: 'inferred'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Questionable date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated qualifier="questionable">1940</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1940',
                  type: 'creation',
                  qualifier: 'questionable'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range plus single date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued keyDate="yes" point="start">1940</dateIssued>
            <dateIssued point="end">1945</dateIssued>
            <dateIssued>1948</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1940',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1945',
                      type: 'end'
                    }
                  ],
                  type: 'publication'
                },
                {
                  value: '1948',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple single dates' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued keyDate="yes">1940</dateIssued>
            <dateIssued>1942</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1940',
                  type: 'publication',
                  status: 'primary'
                },
                {
                  value: '1942',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'BCE date (edtf encoding)' do
    xit 'updated spec - keyDate not implemented' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="edtf">-0499</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '-0499',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  },
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'BCE date range (edtf encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="edtf" point="start">-0599</dateCreated>
            <dateCreated encoding="edtf" point="end">-0499</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '-0599/-0499',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  },
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'CE date (edtf encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="edtf">0800</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '0800',
                  status: 'primary',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'CE date range (edtf encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="edtf" point="start">0800</dateCreated>
            <dateCreated encoding="edtf" point="end">1000</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '0800/1000',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  },
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple date types' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued keyDate="yes">1955</dateIssued>
            <copyrightDate>1940</copyrightDate>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1955',
                  type: 'publication',
                  status: 'primary'
                },
                {
                  value: '1940',
                  type: 'copyright'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Julian calendar - MODS 3.6 and before' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateOther type="Julian">1544-02-02</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              date: [
                {
                  value: '1544-02-02',
                  type: 'Julian'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Julian calendar - MODS 3.7' do
    xit 'not implemented: roundtripping loses calendar Julian note / attrib' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated calendar="Julian">1544-02-02</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              date: [
                {
                  value: '1544-02-02',
                  type: 'creation',
                  note: [
                    {
                      value: 'Julian',
                      type: 'calendar'
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

  describe 'Date range, no start point' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued point="end">1980</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1980',
                      type: 'end'
                    }
                  ],
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range, no end point' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued point="start">1975</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1975',
                      type: 'start'
                    }
                  ],
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'MARC-encoded uncertain date' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated encoding="marc">19uu</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '19uu',
                  type: 'creation',
                  encoding: {
                    code: 'marc'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Unencoded date string' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated>11th century</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '11th century',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'dateOther with type="developed"' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="Place of Creation" eventType="production">
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names"
                valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              displayLabel: 'Place of Creation',
              location: [
                {
                  value: 'Stanford (Calif.)',
                  uri: 'http://id.loc.gov/authorities/names/n50046557',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              date: [
                {
                  value: '2003-11-29',
                  type: 'creation',
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
                  }
                },
                {
                  value: '2003-12-01',
                  type: 'development',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'MODS date types' do
    describe 'dateCreated' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateCreated>1928</dateCreated>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'creation'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateIssued' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateIssued>1928</dateIssued>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'publication'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'copyrightDate' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <copyrightDate>1928</copyrightDate>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'copyright'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateCaptured' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateCaptured>1928</dateCaptured>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'capture'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateValid' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateValid>1928</dateValid>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'validity'
                  }
                ]
              }
            ]
          }
        end
      end
    end

    describe 'dateModified' do
      xit 'not implemented' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateModified>1928</dateModified>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'modification'
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end

  # describe 'dateValid' do
  #   # Adapted from druid:gx929mp5413
  #
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <publisher>Articque informatique</publisher>
  #           <place>
  #             <placeTerm type="text">Fondettes, FR</placeTerm>
  #           </place>
  #           <dateIssued encoding="w3cdtf" keyDate="yes">2010</dateIssued>
  #           <dateValid encoding="w3cdtf">2010</dateValid>
  #           <edition>1</edition>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'publication',
  #             contributor: [
  #               {
  #                 name: [
  #                   {
  #                     value: 'Articque informatique'
  #                   }
  #                 ],
  #                 type: 'organization',
  #                 role: [
  #                   {
  #                     value: 'publisher',
  #                     code: 'pbl',
  #                     uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                     source: {
  #                       code: 'marcrelator',
  #                       uri: 'http://id.loc.gov/vocabulary/relators/'
  #                     }
  #                   }
  #                 ]
  #               }
  #             ],
  #             location: [
  #               {
  #                 value: 'Fondettes, FR'
  #               }
  #             ],
  #             date: [
  #               {
  #                 value: '2010',
  #                 type: 'publication',
  #                 encoding: {
  #                   code: 'w3cdtf'
  #                 },
  #                 status: 'primary'
  #               },
  #               {
  #                 value: '2010',
  #                 type: 'validity',
  #                 encoding: {
  #                   code: 'w3cdtf'
  #                 }
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'edition',
  #                 value: '1'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  context 'Cocina event type > MODS event/date type' do
    # Cocina date type takes precedent over event type in determining
    # which MODS date element to use
    describe 'acquisition' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              type: 'acquisition',
              {
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="acquisition">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'capture' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              type: 'capture',
              {
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:roundtrip_cocina) do
          {
            event: [
              type: 'capture',
              {
                date: [
                  {
                    value: '1928',
                    type: 'capture'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="capture">
              <dateCaptured>1928</dateCaptured>
            </originInfo>
          XML
        end
      end
    end

    describe 'collection' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'collection',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="collection">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'copyright' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'copyright',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:roundtrip_cocina) do
          {
            event: [
              {
                type: 'copyright',
                date: [
                  {
                    value: '1928',
                    type: 'copyright'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="copyright">
              <copyrightDate>1928</copyrightDate>
            </originInfo>
          XML
        end
      end
    end

    describe 'creation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="creation">
              <dateCreated>1928</dateCreated>
            </originInfo>
          XML
        end
      end
    end

    describe 'degree conferral' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'degree conferral',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="date conferral">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'development' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'development',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="development">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'distribution' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'distribution',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="distribution">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'generation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'generation',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="generation">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'manufacture' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'manufacture',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="manufacture">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'modification' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'modification',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:roundtrip_cocina) do
          {
            event: [
              {
                type: 'modification',
                date: [
                  {
                    value: '1928',
                    type: 'modification'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="modification">
              <dateModified>1928</dateModified>
            </originInfo>
          XML
        end
      end
    end

    describe 'performance' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'performance',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="performance">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'presentation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'presentation',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="presentation">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'production' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'production',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo evenType="production">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'publication' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:roundtrip_cocina) do
          {
            event: [
              {
                type: 'publication',
                date: [
                  {
                    value: '1928',
                    type: 'publication'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="publication">
              <dateIssued>1928</dateIssued>
            </originInfo>
          XML
        end
      end
    end

    describe 'recording' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'recording',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="recording">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'release' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'release',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="release">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'submission' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'submission',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="submission">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'validity' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'validity',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:roundtrip_cocina) do
          {
            event: [
              {
                type: 'validity',
                date: [
                  {
                    value: '1928',
                    type: 'validity'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="validity">
              <dateValid>1928</dateValid>
            </originInfo>
          XML
        end
      end
    end

    describe 'withdrawal' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'withdrawal',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="withdrawal">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'other event type not listed above' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                type: 'deaccession',
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo eventType="deaccession">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end

        let(:warnings) { [Notification.new(msg: 'Unrecognized event type') ] }
      end
    end
  end

  context 'Cocina date type > MODS date type' do
    describe 'acquisition' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'acquisition'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="acquisition">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'capture' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'capture'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateCaptured>1928</dateCaptured>
            </originInfo>
          XML
        end
      end
    end

    describe 'collection' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'collection'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="collection">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'copyright' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'copyright'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <copyrightDate>1928</copyrightDate>
            </originInfo>
          XML
        end
      end
    end

    describe 'creation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'creation'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateCreated>1928</dateCreated>
            </originInfo>
          XML
        end
      end
    end

    describe 'degree conferral' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'degree conferral'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="date conferral">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'development' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'development'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="development">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'distribution' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'distribution'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="distribution">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'generation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'generation'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="generation">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'manufacture' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'manufacture'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="manufacture">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'modification' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'modification'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateModified>1928</dateModified>
            </originInfo>
          XML
        end
      end
    end

    describe 'performance' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'performance'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="performance">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'presentation' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'presentation'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="presentation">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'production' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'production'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="production">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'publication' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'publication'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateIssued>1928</dateIssued>
            </originInfo>
          XML
        end
      end
    end

    describe 'recording' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'recording'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="recording">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'release' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'release'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="release">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'submission' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'submission'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="submission">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'validity' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'validity'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateValid>1928</dateValid>
            </originInfo>
          XML
        end
      end
    end

    describe 'withdrawal' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'withdrawal'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="withdrawal">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'other date type not listed above' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ],
                type: 'deaccession'
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="deaccession">1928</dateOther>
            </originInfo>
          XML
        end

        let(:warnings) { [Notification.new(msg: 'Unrecognized date type') ] }
      end
    end

    describe 'no event type, no date type' do
      xit 'not implemented' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end
  end

  # describe 'Date mapping for recording event type' do
  #   xit 'not implemented: recording event type' do
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'recording',
  #             date: [
  #               {
  #                 value: '1990'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="recording">
  #           <dateCreated>1990</dateCreated>
  #         </originInfo>
  #       XML
  #     end
  #   end
  # end
  #
  # describe 'Date mapping for presentation event type' do
  #   context 'with event type and date only' do
  #     xit 'to be implemented: presentation currently maps to MODS dateIssued, not dateCreated - what do we want?' do
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'presentation',
  #               date: [
  #                 {
  #                   value: '1990'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="presentation">
  #             <dateCreated>1990</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #     end
  #   end
  #
  #   context 'with more complex presentation' do
  #     # from druid:ht706sj6651
  #
  #     # NOTE: cocina -> MODS
  #     it_behaves_like 'cocina MODS mapping' do
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'presentation',
  #               date: [
  #                 {
  #                   value: '2018',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ],
  #               displayLabel: 'Presented',
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'Stanford Institute for Theoretical Economics'
  #                     }
  #                   ],
  #                   type: 'organization',
  #                   role: [
  #                     {
  #                       value: 'publisher',
  #                       code: 'pbl',
  #                       uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                       source: {
  #                         code: 'marcrelator',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/'
  #                       }
  #                     }
  #                   ]
  #                 }
  #               ],
  #               location: [
  #                 {
  #                   uri: 'http://id.loc.gov/authorities/names/n50046557',
  #                   value: 'Stanford (Calif.)'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Presented" eventType="presentation">
  #             <place>
  #               <placeTerm type="text" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
  #             </place>
  #             <publisher>Stanford Institute for Theoretical Economics</publisher>
  #             <dateIssued keyDate="yes" encoding="w3cdtf">2018</dateIssued>
  #           </originInfo>
  #         XML
  #       end
  #     end
  #   end
  #
  #   context 'with an originInfo that is a presentation' do
  #     # from druid:ht706sj6651
  #
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Presented" eventType="presentation">
  #             <place>
  #               <placeTerm type="text" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
  #             </place>
  #             <publisher>Stanford Institute for Theoretical Economics</publisher>
  #             <dateIssued keyDate="yes" encoding="w3cdtf">2018</dateIssued>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'presentation',
  #               date: [
  #                 {
  #                   value: '2018',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ],
  #               displayLabel: 'Presented',
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'Stanford Institute for Theoretical Economics'
  #                     }
  #                   ],
  #                   type: 'organization',
  #                   role: [
  #                     {
  #                       value: 'publisher',
  #                       code: 'pbl',
  #                       uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                       source: {
  #                         code: 'marcrelator',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/'
  #                       }
  #                     }
  #                   ]
  #                 }
  #               ],
  #               location: [
  #                 {
  #                   uri: 'http://id.loc.gov/authorities/names/n50046557',
  #                   value: 'Stanford (Calif.)'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  # end
  #
  # describe 'Date mapping for performance event type' do
  #   xit 'not implemented: performance event type' do
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'performance',
  #             date: [
  #               {
  #                 value: '1990'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="performance">
  #           <dateCreated>1990</dateCreated>
  #         </originInfo>
  #       XML
  #     end
  #   end
  # end
  #
  # describe 'Date mapping for release event type' do
  #   xit 'not implemented: release event bug! (also has reverse mapped in H2 spec)' do
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'release',
  #             date: [
  #               {
  #                 value: '1990'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="release">
  #           <dateIssued>1990</dateIssued>
  #         </originInfo>
  #       XML
  #     end
  #   end
  # end


  # Bad data handling

  describe 'Date range, empty qualifier attribute' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start" qualifier="">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        XML
      end

      # remove empty qualifier attribute
      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1920',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1925',
                      type: 'end'
                    }
                  ],
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Date range, empty encoding attribute' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start" encoding="">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        XML
      end

      # remove empty encoding attribute
      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  structuredValue: [
                    {
                      value: '1920',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1925',
                      type: 'end'
                    }
                  ],
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with a simple dateCreated with a trailing period' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated>1980.</dateCreated>
          </originInfo>
        XML
      end

      # add eventType, remove trailing period
      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated>1980</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '1980'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when dateIssued with encoding and keyDate but no value' do
    # based on #vj932ns8042
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued encoding="w3cdtf" keyDate="yes"/>
            <publisher>blah</publisher>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <publisher>blah</publisher>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              note: [
                {
                  source: {
                    value: 'MODS issuance terms'
                  },
                  type: 'issuance',
                  value: 'monographic'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'blah'
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
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  # context 'with a single dateOther' do
  #   describe 'with type attribute on the dateOther element' do
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo>
  #             <dateOther type="Islamic">1441 AH</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               date: [
  #                 {
  #                   value: '1441 AH',
  #                   note: [
  #                     {
  #                       value: 'Islamic',
  #                       type: 'date type'
  #                     }
  #                   ]
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
  #     end
  #   end
  #
  #   describe 'with eventType attribute at the originInfo level' do
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="acquisition" displayLabel="Acquisition date">
  #             <dateOther encoding="w3cdtf">1992</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'acquisition',
  #               displayLabel: 'Acquisition date',
  #               date: [
  #                 {
  #                   value: '1992',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   }
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   describe 'without any type attribute, with displayLabel' do
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Acquisition date">
  #             <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               displayLabel: 'Acquisition date',
  #               date: [
  #                 {
  #                   value: '1970-11-23',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
  #     end
  #   end
  # end

  # context 'with issuance for a creation event' do
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="production">
  #           <dateCreated encoding="w3cdtf" keyDate="yes">1988-08-03</dateCreated>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'creation',
  #             date: [
  #               {
  #                 value: '1988-08-03',
  #                 status: 'primary',
  #                 encoding: {
  #                   code: 'w3cdtf'
  #                 }
  #               }
  #             ],
  #             note: [
  #               {
  #                 value: 'monographic',
  #                 type: 'issuance',
  #                 source: {
  #                   value: 'MODS issuance terms'
  #                 }
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # context 'when it has a single dateOther' do
  #   context 'with eventType="acquisition"' do
  #     # NOTE: cocina -> MODS
  #     it_behaves_like 'cocina MODS mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="acquisition">
  #             <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'acquisition',
  #               date: [
  #                 {
  #                   value: '1970-11-23',
  #                   status: 'primary',
  #                   encoding:
  #                     {
  #                       code: 'w3cdtf'
  #                     }
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'without note, with displayLabel' do
  #     # NOTE: cocina -> MODS
  #     it_behaves_like 'cocina MODS mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Acquisition date">
  #             <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               displayLabel: 'Acquisition date',
  #               date: [
  #                 {
  #                   value: '1970-11-23',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       # for MODS -> cocina
  #       let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
  #     end
  #   end
  # end

  # context 'with originInfo with dateIssued with single point' do
  #   # from druid:bm971cx9348
  #
  #   # NOTE: cocina -> MODS
  #   it_behaves_like 'cocina MODS mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <dateIssued>[192-?]-[193-?]</dateIssued>
  #           <dateIssued encoding="marc" point="start">1920</dateIssued>
  #           <place>
  #             <placeTerm type="text">London</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="code" authority="marccountry">enk</placeTerm>
  #           </place>
  #           <publisher>H.M. Stationery Off</publisher>
  #           <edition>2nd ed.</edition>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'publication',
  #             date: [
  #               {
  #                 value: '[192-?]-[193-?]'
  #               },
  #               {
  #                 value: '1920',
  #                 encoding: {
  #                   code: 'marc'
  #                 },
  #                 type: 'start'
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'edition',
  #                 value: '2nd ed.'
  #               },
  #               {
  #                 source: {
  #                   value: 'MODS issuance terms'
  #                 },
  #                 type: 'issuance',
  #                 value: 'monographic'
  #               }
  #             ],
  #             contributor: [
  #               {
  #                 name: [
  #                   {
  #                     value: 'H.M. Stationery Off'
  #                   }
  #                 ],
  #                 type: 'organization',
  #                 role: [
  #                   {
  #                     value: 'publisher',
  #                     code: 'pbl',
  #                     uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                     source: {
  #                       code: 'marcrelator',
  #                       uri: 'http://id.loc.gov/vocabulary/relators/'
  #                     }
  #                   }
  #                 ]
  #               }
  #             ],
  #             location: [
  #               {
  #                 value: 'London'
  #               },
  #               {
  #                 source: {
  #                   code: 'marccountry'
  #                 },
  #                 code: 'enk'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # context 'when originInfo dateOther[@type] matches eventType and dateOther is empty' do
  #   # based on #xv158sd4671
  #
  #   # Temporarily ignoring <originInfo> pending https://github.com/sul-dlss/dor-services-app/issues/2128
  #   xit 'need to deal with dateOther type matching eventType and roundtripping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="distribution">
  #           <place>
  #             <placeTerm type="text">Washington, DC</placeTerm>
  #           </place>
  #           <publisher>blah</publisher>
  #           <dateOther type="distribution"/>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo eventType="distribution">
  #           <place>
  #             <placeTerm type="text">Washington, DC</placeTerm>
  #           </place>
  #           <publisher>blah</publisher>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'distribution',
  #             contributor: [
  #               {
  #                 name: [
  #                   {
  #                     value: 'blah'
  #                   }
  #                 ],
  #                 type: 'organization',
  #                 role: [
  #                   {
  #                     value: 'distributor',
  #                     code: 'dst',
  #                     uri: 'http://id.loc.gov/vocabulary/relators/dst',
  #                     source: {
  #                       code: 'marcrelator',
  #                       uri: 'http://id.loc.gov/vocabulary/relators/'
  #                     }
  #                   }
  #                 ]
  #               }
  #             ],
  #             location: [
  #               {
  #                 value: 'Washington, DC'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end
end
