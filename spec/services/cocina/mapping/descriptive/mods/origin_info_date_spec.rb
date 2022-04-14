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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    it_behaves_like 'MODS cocina mapping' do
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
                  structuredValue: [
                    {
                      value: '-0599',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '-0499',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
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
                  type: 'creation',
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
                  structuredValue: [
                    {
                      value: '0800',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1000',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
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
    it_behaves_like 'MODS cocina mapping' do
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
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
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
                  type: 'developed',
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

  describe 'MODS date types' do
    describe 'dateCreated' do
      it_behaves_like 'MODS cocina mapping' do
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
      it_behaves_like 'MODS cocina mapping' do
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
      it_behaves_like 'MODS cocina mapping' do
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
      it_behaves_like 'MODS cocina mapping' do
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
      it_behaves_like 'MODS cocina mapping' do
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
      it_behaves_like 'MODS cocina mapping' do
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

  describe 'dateValid and dateIssued' do
    # Adapted from druid:gx929mp5413

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Articque informatique</publisher>
            <place>
              <placeTerm type="text">Fondettes, FR</placeTerm>
            </place>
            <dateIssued encoding="w3cdtf" keyDate="yes">2010</dateIssued>
            <dateValid encoding="w3cdtf">2010</dateValid>
            <edition>1</edition>
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
                      value: 'Articque informatique'
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
                  value: 'Fondettes, FR'
                }
              ],
              date: [
                {
                  value: '2010',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  status: 'primary'
                },
                {
                  value: '2010',
                  type: 'validity',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              note: [
                {
                  type: 'edition',
                  value: '1'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Cocina event type > MODS event/date type' do
    # FIXME:  Arcadia has ticket to find/write tests to exercise this comment and move comment to that location
    # If both cocina event type and date type, then the date type should take precedence over the event type
    #  when mapping back to MODS
    describe 'acquisition' do
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                type: 'acquisition',
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                type: 'capture',
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
                type: 'capture',
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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

        let(:roundtrip_cocina) do
          {
            event: [
              {
                type: 'creation',
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
      it_behaves_like 'cocina MODS mapping' do
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
            <originInfo eventType="degree conferral">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'development' do
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
            <originInfo eventType="production">
              <dateOther>1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'publication' do
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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

        let(:warnings) { [Notification.new(msg: 'Unrecognized event type')] }
      end
    end
  end

  describe 'Cocina date type > MODS date type' do
    describe 'acquisition' do
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'acquisition'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'collection'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'degree conferral'
                  }
                ]
              }
            ]
          }
        end

        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="degree conferral">1928</dateOther>
            </originInfo>
          XML
        end
      end
    end

    describe 'development' do
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'development'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'distribution'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'generation'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'manufacture'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'performance'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'presentation'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'production'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'recording'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'release'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'submission'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'withdrawal'
                  }
                ]
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
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [
              {
                date: [
                  {
                    value: '1928',
                    type: 'deaccession'
                  }
                ]
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
      end
    end

    describe 'no event type, no date type' do
      it_behaves_like 'cocina MODS mapping' do
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

        let(:warnings) { [Notification.new(msg: 'Undetermined date type')] }
      end
    end
  end

  describe 'MODS dateIssued with presentation eventType (real example)' do
    # from druid:ht706sj6651

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="Presented" eventType="presentation">
            <place>
              <placeTerm type="text" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <publisher>Stanford Institute for Theoretical Economics</publisher>
            <dateIssued keyDate="yes" encoding="w3cdtf">2018</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'presentation',
              date: [
                {
                  value: '2018',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  status: 'primary',
                  type: 'publication'
                }
              ],
              displayLabel: 'Presented',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Institute for Theoretical Economics'
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
                  uri: 'http://id.loc.gov/authorities/names/n50046557',
                  value: 'Stanford (Calif.)'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'Date range, empty qualifier attribute' do
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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
    # structuredValue type overrides individual date type for cocina -> MODS date element flavor
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

      # remove trailing period
      let(:roundtrip_mods) do
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with a single dateOther' do
    describe 'with type attribute on the dateOther element and no eventType' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <dateOther type="Islamic">1441 AH</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
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

    describe 'with eventType attribute at the originInfo level' do
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

    describe 'without any type attribute, with displayLabel' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo displayLabel="Acquisition date">
              <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
            </originInfo>
          XML
        end

        let(:cocina) do
          {
            event: [
              {
                displayLabel: 'Acquisition date',
                date: [
                  {
                    value: '1970-11-23',
                    encoding: {
                      code: 'w3cdtf'
                    },
                    status: 'primary'
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

  context 'with dateCreated, eventType=production and issuance' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="w3cdtf" keyDate="yes">1988-08-03</dateCreated>
            <issuance>monographic</issuance>
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
                  value: '1988-08-03',
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  type: 'creation'
                }
              ],
              note: [
                {
                  value: 'monographic',
                  type: 'issuance',
                  source: {
                    value: 'MODS issuance terms'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with originInfo with dateIssued with single point' do
    # from druid:bm971cx9348

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued>[192-?]-[193-?]</dateIssued>
            <dateIssued encoding="marc" point="start">1920</dateIssued>
            <place>
              <placeTerm type="text">London</placeTerm>
            </place>
            <place>
              <placeTerm type="code" authority="marccountry">enk</placeTerm>
            </place>
            <publisher>H.M. Stationery Off</publisher>
            <edition>2nd ed.</edition>
            <issuance>monographic</issuance>
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
                  value: '[192-?]-[193-?]',
                  type: 'publication'
                },
                {
                  structuredValue: [
                    {
                      value: '1920',
                      type: 'start'
                    }
                  ],
                  encoding: {
                    code: 'marc'
                  },
                  type: 'publication'
                }
              ],
              note: [
                {
                  type: 'edition',
                  value: '2nd ed.'
                },
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
                      value: 'H.M. Stationery Off'
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
                },
                {
                  source: {
                    code: 'marccountry'
                  },
                  code: 'enk'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when originInfo dateOther[@type] matches eventType and dateOther is empty' do
    # based on #xv158sd4671

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="distribution">
            <place>
              <placeTerm type="text">Washington, DC</placeTerm>
            </place>
            <publisher>blah</publisher>
            <dateOther type="distribution"/>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="distribution">
            <place>
              <placeTerm type="text">Washington, DC</placeTerm>
            </place>
            <publisher>blah</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'distribution',
              contributor: [
                {
                  name: [
                    {
                      value: 'blah'
                    }
                  ],
                  role: [
                    {
                      value: 'distributor',
                      code: 'dst',
                      uri: 'http://id.loc.gov/vocabulary/relators/dst',
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
                  value: 'Washington, DC'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # added by devs

  context 'when keyDate is on start and end of point' do
    # based on wz774ws7198, fs078fy1458
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated encoding="w3cdtf" keyDate="yes" point="start" qualifier="approximate">1175</dateCreated>
            <dateCreated encoding="w3cdtf" keyDate="yes" point="end" qualifier="approximate">1325</dateCreated>
          </originInfo>
        XML
      end

      # keyDate removed from endpoint
      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <dateCreated encoding="w3cdtf" keyDate="yes" point="start" qualifier="approximate">1175</dateCreated>
            <dateCreated encoding="w3cdtf" point="end" qualifier="approximate">1325</dateCreated>
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
                      value: '1175',
                      type: 'start',
                      status: 'primary'
                    },
                    {
                      value: '1325',
                      type: 'end'
                    }
                  ],
                  qualifier: 'approximate',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when end point date only with keyDate=yes' do
    # based on gd436kk2484, kq971bk2940, mv125bf6089, nz219st6133
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="end">1948</dateCreated>
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
                      value: '1948',
                      status: 'primary',
                      type: 'end'
                    }
                  ],
                  encoding: {
                    code: 'w3cdtf'
                  },
                  qualifier: 'approximate',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when useless dateIssued' do
    # based on vj932ns8042

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued encoding="w3cdtf" keyDate="yes"/>
            <publisher>United Nations Conference on Trade &amp;  Employment</publisher>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <publisher>United Nations Conference on Trade &amp;  Employment</publisher>
            <issuance>monographic</issuance>
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
                      value: 'United Nations Conference on Trade &  Employment'
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
              note: [
                {
                  value: 'monographic',
                  type: 'issuance',
                  source: {
                    value: 'MODS issuance terms'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when edtf with single digit date value' do
    # based on wf185fz5396
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated keyDate="yes" encoding="edtf" qualifier="approximate" point="start">0</dateCreated>
            <dateCreated encoding="edtf" qualifier="approximate" point="end">200</dateCreated>
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
                      value: '0',
                      status: 'primary',
                      type: 'start'
                    },
                    {
                      value: '200',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  qualifier: 'approximate',
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

  describe 'edtf dates should not become dateOther' do
    # based on wf395pf7684
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="Place of creation">
            <dateIssued keyDate="yes" encoding="edtf" point="start">103</dateIssued>
            <dateIssued encoding="edtf" point="end">111</dateIssued>
          </originInfo>
        XML
      end

      # trailing slash on placeTerm authorityURI
      let(:roundtrip_mods) do
        <<~XML
          <originInfo displayLabel="Place of creation">
            <dateIssued keyDate="yes" encoding="edtf" point="start">103</dateIssued>
            <dateIssued encoding="edtf" point="end">111</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              displayLabel: 'Place of creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '103',
                      status: 'primary',
                      type: 'start'
                    },
                    {
                      value: '111',
                      type: 'end'
                    }
                  ],
                  type: 'publication',
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
end
