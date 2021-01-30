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

  describe 'Single dateIssued (with encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued encoding="w3cdtf">1928</dateIssued>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">1928</dateIssued>
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
                  value: '1928',
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="copyright">
            <copyrightDate>1930</copyrightDate>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'copyright',
              date: [
                {
                  value: '1930'
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="capture">
            <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'capture',
              date: [
                {
                  value: '20131012231249',
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
                  note: [
                    {
                      value: 'Islamic',
                      type: 'date type'
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
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
                  ]
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated qualifier="approximate">1940</dateCreated>
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
                  value: '1940',
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
            <dateCreated point="end" qualifier="approximate">1945</dateCreated>
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
            <dateCreated point="end">1945</dateCreated>
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
                  ]
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start">1940</dateCreated>
            <dateCreated point="end" qualifier="approximate">1945</dateCreated>
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
                  ]
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated qualifier="inferred">1940</dateCreated>
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
                  value: '1940',
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated qualifier="questionable">1940</dateCreated>
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
                  value: '1940',
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
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
              type: 'publication',
              date: [
                {
                  value: '1948'
                },
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
                  ]
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued keyDate="yes">1940</dateIssued>
            <dateIssued>1942</dateIssued>
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
                  value: '1940',
                  status: 'primary'
                },
                {
                  value: '1942'
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
            <dateCreated encoding="edtf">-0499</dateCreated>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="edtf">-0499</dateCreated>
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
                  value: '-0499',
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

  describe 'BCE date range (edtf encoding)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated encoding="edtf" point="start">-0499</dateCreated>
            <dateCreated encoding="edtf" point="end">-0599</dateCreated>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="edtf" point="start">-0499</dateCreated>
            <dateCreated encoding="edtf" point="end">-0599</dateCreated>
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
                  structuredValue: [
                    {
                      value: '-0499',
                      type: 'start'
                    },
                    {
                      value: '-0599',
                      type: 'end'
                    }
                  ],
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
            <dateCreated encoding="edtf">0800</dateCreated>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="edtf">0800</dateCreated>
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
                  value: '0800',
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
            <dateCreated encoding="edtf" point="start">0800</dateCreated>
            <dateCreated encoding="edtf" point="end">1000</dateCreated>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="edtf" point="start">0800</dateCreated>
            <dateCreated encoding="edtf" point="end">1000</dateCreated>
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
                  structuredValue: [
                    {
                      value: '0800',
                      type: 'start'
                    },
                    {
                      value: '1000',
                      type: 'end'
                    }
                  ],
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
            <dateIssued>1955</dateIssued>
            <copyrightDate>1940</copyrightDate>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued>1955</dateIssued>
          </originInfo>
          <originInfo eventType="copyright">
            <copyrightDate>1940</copyrightDate>
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
                  value: '1955'
                }
              ]
            },
            {
              type: 'copyright',
              date: [
                {
                  value: '1940'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Julian calendar - MODS 3.6 and before' do
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
            type: 'creation',
            date: [
              {
                value: '1544-02-02',
                note: [
                  {
                    value: 'Julian',
                    type: 'date type'
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

  describe 'Julian calendar - MODS 3.7' do
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
            type: 'creation',
            date: [
              {
                value: '1544-02-02',
                note: [
                  {
                    value: 'Julian',
                    type: 'date type'
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

  describe 'Date range, no start point' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued point="end">1980</dateIssued>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued point="end">1980</dateIssued>
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
                  value: '1980',
                  type: 'end'
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued point="start">1975</dateIssued>
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
                  value: '1975',
                  type: 'start'
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="marc">19uu</dateCreated>
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
                  value: '19uu',
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated>11th century</dateCreated>
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
                  value: '11th century'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'originInfo eventType matches date type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued>1980</dateIssued>
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
                  value: '1980'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'originInfo eventType differs from date type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <copyrightDate>1980</copyrightDate>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="copyright">
            <copyrightDate>1980</copyrightDate>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'copyright',
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

  describe 'originInfo eventType differs from date type, copyright and copyright notice events, converted from MARC record with multiple 264s' do
    it_behaves_like 'MODS cocina mapping' do
      # eventType="copyright" maps to event.date, "copyright notice" maps to event.note
      let(:mods) do
        <<~XML
          <originInfo>
             <place>
                <placeTerm type="code" authority="marccountry">ru</placeTerm>
             </place>
             <dateIssued encoding="marc">2019</dateIssued>
             <copyrightDate encoding="marc">2018</copyrightDate>
             <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication">
             <place>
                <placeTerm type="text">Moskva</placeTerm>
             </place>
             <publisher>Izdatelʹstvo "Vesʹ Mir"</publisher>
             <dateIssued>2019</dateIssued>
          </originInfo>
          <originInfo eventType="copyright notice">
             <copyrightDate>©2018</copyrightDate>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
             <place>
                <placeTerm type="code" authority="marccountry">ru</placeTerm>
             </place>
             <dateIssued encoding="marc">2019</dateIssued>
             <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="copyright">
            <copyrightDate encoding="marc">2018</copyrightDate>
          </originInfo>
          <originInfo eventType="publication">
             <place>
                <placeTerm type="text">Moskva</placeTerm>
             </place>
             <publisher>Izdatelʹstvo "Vesʹ Mir"</publisher>
             <dateIssued>2019</dateIssued>
          </originInfo>
          <originInfo eventType="copyright notice">
             <copyrightDate>©2018</copyrightDate>
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
                  code: 'ru',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              date: [
                {
                  value: '2019',
                  encoding: {
                    code: 'marc'
                  }
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
            },
            {
              type: 'copyright',
              date: [
                {
                  value: '2018',
                  encoding: {
                    code: 'marc'
                  }
                }
              ]
            },
            {
              type: 'publication',
              location: [
                {
                  value: 'Moskva'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Izdatelʹstvo "Vesʹ Mir"'
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
              date: [
                {
                  value: '2019'
                }
              ]
            },
            {
              type: 'copyright',
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

  describe 'Edition' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <edition>1st ed.</edition>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <edition>1st ed.</edition>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              note: [
                {
                  value: '1st ed.',
                  type: 'edition'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Issuance and frequency' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <issuance>serial</issuance>
            <frequency>every full moon</frequency>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <issuance>serial</issuance>
            <frequency>every full moon</frequency>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              note: [
                {
                  value: 'serial',
                  type: 'issuance',
                  source: {
                    value: 'MODS issuance terms'
                  }
                },
                {
                  value: 'every full moon',
                  type: 'frequency'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Issuance and frequency - authorized term' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <issuance>multipart monograph</issuance>
            <frequency authority="marcfrequency">Annual</frequency>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <issuance>multipart monograph</issuance>
            <frequency authority="marcfrequency">Annual</frequency>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              note: [
                {
                  value: 'multipart monograph',
                  type: 'issuance',
                  source: {
                    value: 'MODS issuance terms'
                  }
                },
                {
                  value: 'Annual',
                  type: 'frequency',
                  source: {
                    code: 'marcfrequency'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple originInfo elements for different events' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated>1899</dateCreated>
            <place>
              <placeTerm type="text">York</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="publication">
            <dateIssued>1901</dateIssued>
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
              type: 'creation',
              date: [
                {
                  value: '1899'
                }
              ],
              location: [
                {
                  value: 'York'
                }
              ]
            },
            {
              type: 'publication',
              date: [
                {
                  value: '1901'
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

  describe 'Origin info - multilingual' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo script="Latn" altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Kyōto-shi</placeTerm>
            </place>
            <publisher>Rinsen Shoten</publisher>
            <dateIssued>Heisei 8 [1996]</dateIssued>
            <dateIssued encoding="marc">1996</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo script="Hani" altRepGroup="1">
            <place>
              <placeTerm type="text">京都市</placeTerm>
            </place>
            <publisher>臨川書店</publisher>
            <dateIssued>平成 8 [1996]</dateIssued>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication" script="Latn" altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Kyōto-shi</placeTerm>
            </place>
            <publisher>Rinsen Shoten</publisher>
            <dateIssued>Heisei 8 [1996]</dateIssued>
            <dateIssued encoding="marc">1996</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication" script="Hani" altRepGroup="1">
            <place>
              <placeTerm type="text">京都市</placeTerm>
            </place>
            <publisher>臨川書店</publisher>
            <dateIssued>平成 8 [1996]</dateIssued>
          </originInfo>
        XML
      end

      # Round trip maps back to original plus eventTypes. Rule: anything in an event that does not have an explicit language/script
      # goes in the eng and/or Latn originInfo.
      # See Parallel value with no script given in MODS for mapping when both attributes are absent.
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Kyōto-shi',
                      valueLanguage: {
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: '京都市',
                      valueLanguage: {
                        valueScript: {
                          code: 'Hani',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    }
                  ]
                },
                {
                  code: 'ja',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'Rinsen Shoten',
                          valueLanguage: {
                            valueScript: {
                              code: 'Latn',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        },
                        {
                          value: '臨川書店',
                          valueLanguage: {
                            valueScript: {
                              code: 'Hani',
                              source: {
                                code: 'iso15924'
                              }
                            }
                          }
                        }
                      ]
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
              ],
              date: [
                {
                  parallelValue: [
                    {
                      value: 'Heisei 8 [1996]',
                      valueLanguage: {
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: '平成 8 [1996]',
                      valueLanguage: {
                        valueScript: {
                          code: 'Hani',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    }
                  ]
                },
                {
                  value: '1996',
                  encoding: {
                    code: 'marc'
                  }
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

  describe 'originInfo with displayLabel' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="Origin" eventType="production">
            <place>
              <placeTerm type="text">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              displayLabel: 'Origin',
              location: [
                {
                  value: 'Stanford (Calif.)'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiscript originInfo with eventType production' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production" lang="eng" script="Latn" altRepGroup="1">
            <dateCreated keyDate="yes" encoding="w3cdtf">1999-09-09</dateCreated>
            <place>
              <placeTerm authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n79076156">Moscow</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="production" lang="rus" script="Cyrl" altRepGroup="1">
            <place>
              <placeTerm>Москва</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <originInfo script="Latn" lang="eng" altRepGroup="1" eventType="production">
            <dateCreated encoding="w3cdtf" keyDate="yes">1999-09-09</dateCreated>
            <place>
              <placeTerm type="text" authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n79076156">Moscow</placeTerm>
            </place>
          </originInfo>
          <originInfo script="Cyrl" lang="rus" altRepGroup="1" eventType="production">
            <place>
              <placeTerm type="text">Москва</placeTerm>
            </place>
          </originInfo>
        XML
      end

      # Round trip maps back to original. Rule: same as Origin info - multilingual.

      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '1999-09-09',
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Moscow',
                      uri: 'http://id.loc.gov/authorities/names/n79076156',
                      source: {
                        uri: 'http://id.loc.gov/authorities/names/'
                      },
                      valueLanguage: {
                        code: 'eng',
                        source: {
                          code: 'iso639-2b'
                        },
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: 'Москва',
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

  describe 'Multilingual edition' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication" lang="eng" script="Latn" altRepGroup="1">
            <edition>First edition</edition>
          </originInfo>
          <originInfo eventType="publication" lang="rus" script="Cyrl" altRepGroup="1">
            <edition>Первое издание</edition>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              note: [
                {
                  type: 'edition',
                  parallelValue: [
                    {
                      value: 'First edition',
                      valueLanguage: {
                        code: 'eng',
                        source: {
                          code: 'iso639-2b'
                        },
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: 'Первое издание',
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

  describe 'Parallel value with no script given in MODS - A' do
    # Example adapted from druid:hn285fy7937

    # First <place> not included in parallelValue because it's type="code"
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1">
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005.</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
          </originInfo>
        XML
      end

      # We don't know which originInfo is eng/Latn, so the rule in #39 cannot apply.
      # Instead, put all values that are not parallel values in both originInfo elements.
      # Parallel values are grouped by index (i.e. the first of each pair is in the first originInfo, the second in the second one).
      let(:roundtrip_mods) do
        <<~XML
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end
      # When converting back to COCINA, duplicate values across the originInfos should be collapsed into one to generate the same record as above.

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Chengdu'
                    },
                    {
                      value: '[Chengdu in Chinese]'
                    }
                  ]
                },
                {
                  code: 'cc',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'Sichuan chu ban ji tuan, Sichuan wen yi chu ban she'
                        },
                        {
                          value: '[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]'
                        }
                      ]
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
              ],
              date: [
                {
                  value: '2005'
                }
              ],
              note: [
                {
                  type: 'edition',
                  parallelValue: [
                    {
                      value: 'Di 1 ban.'
                    },
                    {
                      value: '[Di 1 ban in Chinese]'
                    }
                  ]
                },
                {
                  type: 'issuance',
                  value: 'monographic',
                  source: {
                    value: 'MODS issuance terms'
                  }

                }
              ]
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Bad altRepGroup')
        ]
      end
    end
  end

  describe 'Parallel value with no script given in MODS - B' do
    # Example adapted from druid:yc052ns4738
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo altRepGroup="1">
             <place>
                <placeTerm type="code" authority="marccountry">cc</placeTerm>
             </place>
             <dateIssued encoding="marc" point="start">1933</dateIssued>
             <dateIssued encoding="marc" point="end">uuuu</dateIssued>
             <issuance>serial</issuance>
             <frequency>Irregular</frequency>
             <place>
                <placeTerm type="text">[Ruijin]</placeTerm>
             </place>
             <publisher>Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu</publisher>
          </originInfo>
          <originInfo altRepGroup="1">
             <place>
                <placeTerm type="code" authority="marccountry">cc</placeTerm>
             </place>
             <dateIssued encoding="marc" point="start">1933</dateIssued>
             <dateIssued encoding="marc" point="end">uuuu</dateIssued>
             <issuance>serial</issuance>
             <frequency>Irregular</frequency>
             <place>
                <placeTerm type="text">[Ruijin] in Chinese</placeTerm>
             </place>
             <publisher>Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu in Chinese</publisher>
          </originInfo>
        XML
      end

      let(:mods) do
        <<~XML
          <originInfo altRepGroup="1" eventType="publication">
             <place>
                <placeTerm type="code" authority="marccountry">cc</placeTerm>
             </place>
             <dateIssued encoding="marc" point="start">1933</dateIssued>
             <dateIssued encoding="marc" point="end">uuuu</dateIssued>
             <issuance>serial</issuance>
             <place>
                <placeTerm type="text">[Ruijin]</placeTerm>
             </place>
             <publisher>Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu</publisher>
             <frequency>Irregular</frequency>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
             <place>
                <placeTerm type="code" authority="marccountry">cc</placeTerm>
             </place>
             <dateIssued encoding="marc" point="start">1933</dateIssued>
             <dateIssued encoding="marc" point="end">uuuu</dateIssued>
             <issuance>serial</issuance>
             <place>
                <placeTerm type="text">[Ruijin] in Chinese</placeTerm>
             </place>
             <publisher>Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu in Chinese</publisher>
             <frequency>Irregular</frequency>
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
                  parallelValue: [
                    {
                      value: '[Ruijin]'
                    },
                    {
                      value: '[Ruijin] in Chinese'
                    }
                  ]
                },
                {
                  code: 'cc',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              date: [
                {
                  structuredValue: [
                    {
                      value: '1933',
                      type: 'start'
                    },
                    {
                      value: 'uuuu',
                      type: 'end'
                    }
                  ],
                  encoding: {
                    code: 'marc'
                  }
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu'
                        },
                        {
                          value: 'Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu in Chinese'
                        }
                      ]
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
              ],
              note: [
                {
                  type: 'issuance',
                  value: 'serial',
                  source: {
                    value: 'MODS issuance terms'
                  }
                },
                {
                  type: 'frequency',
                  value: 'Irregular'
                }
              ]
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Bad altRepGroup')
        ]
      end
    end
  end

  describe 'Parallel value with no script given in MODS - C' do
    # Example adapted from druid:bh212vz9239
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Guangdong</placeTerm>
            </place>
            <publisher>Guangdong lu jun ce liang ju</publisher>
            <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
            <dateIssued encoding="marc" point="start">1922</dateIssued>
            <dateIssued encoding="marc" point="end">1929</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1">
            <place>
              <placeTerm type="text">Guangdong in Chinese</placeTerm>
            </place>
            <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
            <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
          </originInfo>
        XML
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication" altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Guangdong</placeTerm>
            </place>
            <publisher>Guangdong lu jun ce liang ju</publisher>
            <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
            <dateIssued encoding="marc" point="start">1922</dateIssued>
            <dateIssued encoding="marc" point="end">1929</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication" altRepGroup="1">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Guangdong in Chinese</placeTerm>
            </place>
            <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
            <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
            <dateIssued encoding="marc" point="start">1922</dateIssued>
            <dateIssued encoding="marc" point="end">1929</dateIssued>
            <issuance>monographic</issuance>
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
                  parallelValue: [
                    {
                      value: 'Guangdong'
                    },
                    {
                      value: 'Guangdong in Chinese'
                    }
                  ]
                },
                {
                  code: 'cc',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              contributor: [
                {
                  type: 'organization',
                  name: [
                    {
                      parallelValue: [
                        {
                          value: 'Guangdong lu jun ce liang ju'
                        },
                        {
                          value: 'Guangdong lu jun ce liang ju in Chinese'
                        }
                      ]
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
              ],
              date: [
                {
                  parallelValue: [
                    {
                      value: 'Minguo 11-18 [1922-1929]'
                    },
                    {
                      value: 'Minguo 11-18 [1922-1929] in Chinese'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: '1922',
                      type: 'start'
                    },
                    {
                      value: '1929',
                      type: 'end'
                    }
                  ],
                  encoding: {
                    code: 'marc'
                  }
                }
              ],
              note: [
                {
                  type: 'issuance',
                  value: 'monographic',
                  source: {
                    value: 'MODS issuance terms'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Bad altRepGroup')
        ]
      end
    end
  end

  describe 'Multiple originInfo elements with and without eventTypes' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="code" authority="marccountry">cau</placeTerm>
            </place>
            <dateIssued encoding="marc">2020</dateIssued>
            <copyrightDate encoding="marc">2020</copyrightDate>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">[Stanford, Calif.]</placeTerm>
            </place>
            <publisher>[Stanford University]</publisher>
            <dateIssued>2020</dateIssued>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>&#xA9;2020</copyrightDate>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cau</placeTerm>
            </place>
            <dateIssued encoding="marc">2020</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">[Stanford, Calif.]</placeTerm>
            </place>
            <publisher>[Stanford University]</publisher>
            <dateIssued>2020</dateIssued>
          </originInfo>
          <originInfo eventType="copyright">
            <copyrightDate encoding="marc">2020</copyrightDate>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>&#xA9;2020</copyrightDate>
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
                  code: 'cau',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              date: [
                {
                  value: '2020',
                  encoding: {
                    code: 'marc'
                  }
                }
              ],
              note: [
                {
                  type: 'issuance',
                  value: 'monographic',
                  source: {
                    value: 'MODS issuance terms'
                  }
                }
              ]
            },
            {
              type: 'copyright',
              date: [
                {
                  value: '2020',
                  encoding: {
                    code: 'marc'
                  }
                }
              ]
            },
            {
              type: 'publication',
              location: [
                {
                  value: '[Stanford, Calif.]'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: '[Stanford University]'
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
              date: [
                {
                  value: '2020'
                }
              ]
            },
            {
              type: 'copyright',
              note: [
                {
                  value: '©2020',
                  type: 'copyright statement'
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo displayLabel="Place of Creation" eventType="production">
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
          </originInfo>
          <originInfo eventType="development">
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
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
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'development',
              date: [
                {
                  value: '2003-12-01',
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

  describe 'dateValid' do
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Articque informatique</publisher>
            <place>
              <placeTerm type="text">Fondettes, FR</placeTerm>
            </place>
            <dateIssued encoding="w3cdtf" keyDate="yes">2010</dateIssued>
            <edition>1</edition>
          </originInfo>
          <originInfo eventType="validity">
            <dateValid encoding="w3cdtf">2010</dateValid>
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
                  value: 'Fondettes, FR'
                }
              ],
              date: [
                {
                  value: '2010',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  status: 'primary'
                }
              ],
              note: [
                {
                  type: 'edition',
                  value: '1'
                }
              ]
            },
            {
              type: 'validity',
              date: [
                {
                  value: '2010',
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
end
