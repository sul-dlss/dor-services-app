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
    end
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

    xit 'not implemented: roundtripping loses calendar Julian note / attrib'
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

  describe 'Date mapping for recording event type' do
    xit 'not implemented'

    let(:cocina) do
      {
        event: [
          {
            type: 'recording',
            date: [
              {
                value: '1990'
              }
            ]
          }
        ]
      }
    end

    let(:mods) do
      <<~XML
        <originInfo eventType="recording">
          <dateCreated>1990</dateCreated>
        </originInfo>
      XML
    end
  end

  describe 'Date mapping for presentation event type' do
    xit 'not implemented' # or is it?

    let(:cocina) do
      {
        event: [
          {
            type: 'presentation',
            date: [
              {
                value: '1990'
              }
            ]
          }
        ]
      }
    end

    let(:mods) do
      <<~XML
        <originInfo eventType="presentation">
          <dateCreated>1990</dateCreated>
        </originInfo>
      XML
    end
  end

  describe 'Date mapping for performance event type' do
    xit 'not implemented'

    let(:cocina) do
      {
        event: [
          {
            type: 'performance',
            date: [
              {
                value: '1990'
              }
            ]
          }
        ]
      }
    end

    let(:mods) do
      <<~XML
        <originInfo eventType="performance">
          <dateCreated>1990</dateCreated>
        </originInfo>
      XML
    end
  end

  describe 'Date mapping for release event type' do
    xit 'not implemented' # also mapped in H2

    let(:cocina) do
      {
        event: [
          {
            type: 'release',
            date: [
              {
                value: '1990'
              }
            ]
          }
        ]
      }
    end

    let(:mods) do
      <<~XML
        <originInfo eventType="release">
          <dateIssued>1990</dateIssued>
        </originInfo>
      XML
    end
  end

  # specs added by devs below

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

  context 'with a single dateOther' do
    describe 'with type attribute on the dateOther element' do
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

        let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
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

        let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
      end
    end
  end

  context 'with issuance for a creation event' do
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
              type: 'creation',
              date: [
                {
                  value: '1988-08-03',
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
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

  context 'with an originInfo that is a presentation' do
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
                  status: 'primary'
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

  context 'when it has a single dateOther' do
    context 'with eventType="acquisition"' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="acquisition">
              <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
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
                    value: '1970-11-23',
                    status: 'primary',
                    encoding:
                      {
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

    context 'without note, with displayLabel' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
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

        # for MODS -> cocina
        let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
      end
    end
  end

  context 'with originInfo with dateIssued with single point' do
    # from druid:bm971cx9348

    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
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
                  value: '[192-?]-[193-?]'
                },
                {
                  value: '1920',
                  encoding: {
                    code: 'marc'
                  },
                  type: 'start'
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

  context 'with presentation' do
    # from druid:ht706sj6651

    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
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
                  status: 'primary'
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
end
