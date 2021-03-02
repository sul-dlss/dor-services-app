# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings' do
  describe 'Edition' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo>
            <edition>1st ed.</edition>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
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
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo>
            <issuance>serial</issuance>
            <frequency>every full moon</frequency>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
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
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo>
            <issuance>multipart monograph</issuance>
            <frequency authority="marcfrequency">Annual</frequency>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
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

  describe 'Multiple originInfo elements with different event types' do
    xit 'updated spec' do
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
              type: 'production',
              date: [
                {
                  value: '1899',
                  type: 'creation'
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
                  value: '1901',
                  type: 'publication'
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

  describe 'Multiple originInfo elements with and without event types' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo>
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
              date: [
                {
                  value: '1899',
                  type: 'creation'
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
                  value: '1901',
                  type: 'publication'
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

  describe 'Converted from MARC record with multiple 264s' do
    # eventType="copyright" maps to event.date, "copyright notice" maps to event.note
    xit 'updated spec' do
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

      let(:cocina) do
        {
          event: [
            {
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
                  type: 'publication',
                  encoding: {
                    code: 'marc'
                  }
                },
                {
                  value: '2018',
                  type: 'copyright',
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
                  value: '2019',
                  type: 'publication'
                }
              ]
            },
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
              type: 'production',
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

  describe 'Parallel value' do
    xit 'updated spec' do
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

      let(:cocina) do
        {
          event: [
            {
              parallelEvent: [
                {
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  },
                  location: [
                    {
                      code: 'ja',
                      source: {
                        code: 'marccountry'
                      }
                    },
                    {
                      value: 'Kyōto-shi'
                    }
                  ],
                  contributor: [
                    {
                      name: [
                        {
                          value: 'Rinsen Shoten'
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
                },
                {
                  valueLanguage: {
                    valueScript: {
                      code: 'Hani',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  },
                  location: [
                    {
                      value: '京都市'
                    }
                  ],
                  contributor: [
                    {
                      name: [
                        {
                          value: '臨川書店'
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
                      value: '平成 8 [1996]',
                      type: 'publication'
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

  describe 'Parallel value with eventType, language, and displayLabel' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production" displayLabel="Original" lang="eng" script="Latn" altRepGroup="1">
            <dateCreated keyDate="yes" encoding="w3cdtf">1999-09-09</dateCreated>
            <place>
              <placeTerm authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n79076156">Moscow</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="production" displayLabel="Original" lang="rus" script="Cyrl" altRepGroup="1">
            <place>
              <placeTerm>Москва</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              displayLabel: 'Original',
              parallelEvent: [
                {
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
                  },
                  date: [
                    {
                      value: '1999-09-09',
                      type: 'creation',
                      status: 'primary',
                      encoding: {
                        code: 'w3cdtf'
                      }
                    }
                  ],
                  location: [
                    {
                      value: 'Moscow',
                      uri: 'http://id.loc.gov/authorities/names/n79076156',
                      source: {
                        uri: 'http://id.loc.gov/authorities/names/'
                      }
                    }
                  ]
                },
                {
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: [
                      {
                        code: 'Cyrl',
                        source: {
                          code: 'iso15924'
                        }
                      }
                    ]
                  },
                  location: [
                    {
                      value: 'Москва'
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

  describe 'Parallel value with single subelement' do
    xit 'updated spec' do
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
              parallelEvent: [
                {
                  note: [
                    {
                      type: 'edition',
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
                    }
                  ]
                },
                {
                  note: [
                    {
                      type: 'edition',
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

  describe 'Parallel value including duplicate subelement' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication" lang="eng" script="Latn" altRepGroup="1">
            <edition>First edition</edition>
            <dateIssued>1928</dateIssued>
          </originInfo>
          <originInfo eventType="publication" lang="rus" script="Cyrl" altRepGroup="1">
            <edition>Первое издание</edition>
            <dateIssued>1928</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              parallelEvent: [
                {
                  note: [
                    {
                      type: 'edition',
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
                    }
                  ],
                  date: [
                    {
                      value: '1928',
                      type: 'publication'
                    }
                  ]
                },
                {
                  note: [
                    {
                      type: 'edition',
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
                  ],
                  date: [
                    {
                      value: '1928',
                      type: 'publication'
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

  describe 'Parallel value with no script given in MODS' do
    # Example adapted from druid:hn285fy7937
    xit 'updated spec' do
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
              <placeTerm type="text"> 成都</placeTerm>
            </place>
            <publisher>四川出版集团，四川文艺出版社</publisher>
            <dateIssued>2005年</dateIssued>
            <edition>第1版</edition>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              parallelEvent: [
                {
                  location: [
                    {
                      code: 'cc',
                      source: {
                        code: 'marccountry'
                      }
                    },
                    {
                      value: 'Chengdu'
                    }
                  ],
                  contributor: [
                    {
                      name: [
                        {
                          value: 'Sichuan chu ban ji tuan, Sichuan wen yi chu ban she'
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
                      value: '2005',
                      type: 'publication'
                    }
                  ],
                  note: [
                    {
                      value: 'Di 1 ban.',
                      type: 'edition'
                    },
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
                  location: [
                    {
                      value: '成都'
                    }
                  ],
                  contributor: [
                    {
                      name: [
                        {
                          value: '四川出版集团，四川文艺出版社'
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
                      value: '2005年',
                      type: 'publication'
                    }
                  ],
                  note: [
                    {
                      value: '第1版',
                      type: 'edition'
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

  describe 'Parallel value with same displayLabel' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication" displayLabel="Edition" lang="eng" script="Latn" altRepGroup="1">
            <edition>First edition</edition>
          </originInfo>
          <originInfo eventType="publication" displayLabel="Edition" lang="rus" script="Cyrl" altRepGroup="1">
            <edition>Первое издание</edition>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              displayLabel: 'Edition',
              parallelEvent: [
                {
                  note: [
                    {
                      type: 'edition',
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
                    }
                  ]
                },
                {
                  note: [
                    {
                      type: 'edition',
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

  describe 'Parallel value with different displayLabel' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication" displayLabel="edition" lang="eng" script="Latn" altRepGroup="1">
            <edition>First edition</edition>
            <dateIssued>1928</dateIssued>
          </originInfo>
          <originInfo eventType="publication" displayLabel="издание" lang="rus" script="Cyrl" altRepGroup="1">
            <edition>Первое издание</edition>
            <dateIssued>1928</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              parallelEvent: [
                {
                  displayLabel: 'edition',
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
                  },
                  note: [
                    {
                      value: 'First edition',
                      type: 'edition'
                    }
                  ],
                  date: [
                    {
                      value: '1928',
                      type: 'publication'
                    }
                  ]
                },
                {
                  displayLabel: 'издание',
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
                  },
                  note: [
                    {
                      value: 'Первое издание',
                      type: 'edition'
                    }
                  ],
                  date: [
                    {
                      value: '1928',
                      type: 'publication'
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

  context 'when multiple altRepGroups and a singular originInfo' do
    # based on sf449my9678, hb891vx5415, ng725mp5358
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="marc" point="start">1980</dateIssued>
            <dateIssued encoding="marc" point="end">1984</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <edition>Di 1 ban.</edition>
          </originInfo>
          <originInfo altRepGroup="2" eventType="publication">
            <publisher>Sichuan ren min chu ban she</publisher>
            <dateIssued>1980-1984</dateIssued>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <edition>第1版．</edition>
          </originInfo>
          <originInfo altRepGroup="2" eventType="publication">
            <publisher>四川人民出版社：</publisher>
            <dateIssued>1980-1984</dateIssued>
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
                  structuredValue: [
                    {
                      value: '1980',
                      type: 'start'
                    },
                    {
                      value: '1984',
                      type: 'end'
                    }
                  ],
                  type: 'publication',
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
              type: 'publication',
              parallelEvent: [
                {
                  note: [
                    {
                      value: 'Di 1 ban.',
                      type: 'edition'
                    }
                  ]
                },
                {
                  note: [
                    {
                      value: '第1版．',
                      type: 'edition'
                    }
                  ]
                }
              ]
            },
            {
              type: 'publication',
              parallelEvent: [
                {
                  contributor: [
                    {
                      name: [
                        {
                          value: 'Sichuan ren min chu ban she'
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
                      value: '1980-1984',
                      type: 'publication'
                    }
                  ]
                },
                {
                  contributor: [
                    {
                      name: [
                        {
                          value: '四川人民出版社：'
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
                      value: '1980-1984',
                      type: 'publication'
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

  # Bad data handling

  context 'when altRepGroup script values match (incorrectly)' do
    # based on rz633ck7860
    # it_behaves_like 'MODS cocina mapping' do
    xit 'implemented?' do
      let(:mods) do
        <<~XML
          <originInfo script="Latn" altRepGroup="1" eventType="publication">
            <publisher>Rikuchi Sokuryōbu</publisher>
            <dateIssued>Shōwa 16 [1941]</dateIssued>
            <dateIssued encoding="marc" point="start">1941</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo script="Latn" altRepGroup="1" eventType="publication">
            <publisher>陸地測量部 :</publisher>
            <dateIssued>昭和 16 [1941]</dateIssued>
            <dateIssued encoding="marc" point="start">1941</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              parallelEvent: [
                {
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  },
                  contributor: [
                    {
                      name: [
                        {
                          value: 'Rikuchi Sokuryōbu'
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
                      value: 'Shōwa 16 [1941]',
                      type: 'publication'
                    },
                    {
                      structuredValue: [
                        {
                          value: '1941',
                          type: 'start'
                        }
                      ],
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
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  },
                  contributor: [
                    {
                      name: [
                        {
                          value: '陸地測量部 :'
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
                      value: '昭和 16 [1941]',
                      type: 'publication'
                    },
                    {
                      structuredValue: [
                        {
                          value: '1941',
                          type: 'start'
                        }
                      ],
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
          ]
        }
      end
    end
  end

  # Empty value handling
  # Naomi: Are these still needed?
  context 'when originInfo / event is various flavors of missing' do
    context 'when cocina event is empty array' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: []
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) { '' }
      end
    end

    context 'when MODS has no elements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) { '' }

        let(:cocina) do
          {
          }
        end
      end
    end

    context 'when cocina event is array with empty hash' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            event: [{}]
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) { '' }
      end
    end

    context 'when MODS is empty originInfo element with no attributes' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo/>
          XML
        end

        let(:roundtrip_mods) { '' }

        let(:cocina) do
          {
          }
        end
      end
    end
  end

  # describe 'originInfo eventType matches date type' do
  #   xit 'updated spec' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <dateIssued>1980</dateIssued>
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
  #                 value: '1980',
  #                 type: 'publication'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end
  #
  # describe 'originInfo eventType differs from date type' do
  #   xit 'updated spec' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <copyrightDate>1980</copyrightDate>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo eventType="copyright">
  #           <copyrightDate>1980</copyrightDate>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'copyright',
  #             date: [
  #               {
  #                 value: '1980'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # describe 'Parallel value with no script given in MODS - C' do
  #   # Example adapted from druid:bh212vz9239
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo altRepGroup="1">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo altRepGroup="1">
  #           <place>
  #             <placeTerm type="text">Guangdong in Chinese</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo eventType="publication" altRepGroup="1">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo eventType="publication" altRepGroup="1">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong in Chinese</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
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
  #             location: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Guangdong'
  #                   },
  #                   {
  #                     value: 'Guangdong in Chinese'
  #                   }
  #                 ]
  #               },
  #               {
  #                 code: 'cc',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               }
  #             ],
  #             contributor: [
  #               {
  #                 type: 'organization',
  #                 name: [
  #                   {
  #                     parallelValue: [
  #                       {
  #                         value: 'Guangdong lu jun ce liang ju'
  #                       },
  #                       {
  #                         value: 'Guangdong lu jun ce liang ju in Chinese'
  #                       }
  #                     ]
  #                   }
  #                 ],
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
  #             date: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Minguo 11-18 [1922-1929]'
  #                   },
  #                   {
  #                     value: 'Minguo 11-18 [1922-1929] in Chinese'
  #                   }
  #                 ]
  #               },
  #               {
  #                 structuredValue: [
  #                   {
  #                     value: '1922',
  #                     type: 'start'
  #                   },
  #                   {
  #                     value: '1929',
  #                     type: 'end'
  #                   }
  #                 ],
  #                 encoding: {
  #                   code: 'marc'
  #                 }
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'issuance',
  #                 value: 'monographic',
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

  # describe 'Parallel value with no script given in MODS, duplicate values' do
  #   # Example adapted from druid:yc052ns4738
  #   # Subelements that are exact duplicates become siblings of parallelValue and
  #   #  map back to both originInfo elements in roundtrip.
  #   xit 'updated mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo altRepGroup="1">
  #            <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #            </place>
  #            <dateIssued encoding="marc" point="start">1933</dateIssued>
  #            <dateIssued encoding="marc" point="end">uuuu</dateIssued>
  #            <issuance>serial</issuance>
  #            <frequency>Irregular</frequency>
  #            <place>
  #               <placeTerm type="text">[Ruijin]</placeTerm>
  #            </place>
  #            <publisher>Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu</publisher>
  #         </originInfo>
  #         <originInfo altRepGroup="1">
  #            <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #            </place>
  #            <dateIssued encoding="marc" point="start">1933</dateIssued>
  #            <dateIssued encoding="marc" point="end">uuuu</dateIssued>
  #            <issuance>serial</issuance>
  #            <frequency>Irregular</frequency>
  #            <place>
  #               <placeTerm type="text">[瑞金]</placeTerm>
  #            </place>
  #            <publisher>中央革命軍事委員会總衛生部</publisher>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             parallelEvent: [
  #               {
  #                 location: [
  #                   {
  #                     value: '[Ruijin]'
  #                   }
  #                 ],
  #                 contributor: [
  #                   {
  #                     name: [
  #                       {
  #                         value: 'Zhong yang ge ming jun shi wei yuan hui zong wei sheng bu'
  #                       }
  #                     ],
  #                     role: [
  #                       {
  #                         value: 'publisher',
  #                         code: 'pbl',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                         source: {
  #                           code: 'marcrelator',
  #                           uri: 'http://id.loc.gov/vocabulary/relators/'
  #                         }
  #                       }
  #                     ]
  #                   }
  #                 ]
  #               },
  #               {
  #                 location: [
  #                   {
  #                     value: '[瑞金]'
  #                   }
  #                 ],
  #                 contributor: [
  #                   {
  #                     name: [
  #                       {
  #                         value: '中央革命軍事委員会總衛生部'
  #                       }
  #                     ],
  #                     role: [
  #                       {
  #                         value: 'publisher',
  #                         code: 'pbl',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                         source: {
  #                           code: 'marcrelator',
  #                           uri: 'http://id.loc.gov/vocabulary/relators/'
  #                         }
  #                       }
  #                     ]
  #                   }
  #                 ]
  #               }
  #             ],
  #             location: [
  #               {
  #                 code: 'cc',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               }
  #             ],
  #             date: [
  #               {
  #                 structuredValue: [
  #                   {
  #                     value: '1933',
  #                     type: 'start'
  #                   },
  #                   {
  #                     value: 'uuuu',
  #                     type: 'end'
  #                   }
  #                 ],
  #                 encoding: 'marc',
  #                 type: 'publication'
  #               }
  #             ],
  #             note: [
  #               {
  #                 value: 'serial',
  #                 type: 'issuance',
  #                 source: {
  #                   value: 'MODS issuance terms'
  #                 }
  #               },
  #               {
  #                 value: 'Irregular',
  #                 type: 'frequency'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # describe 'Multiple originInfo elements with and without eventTypes' do
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo>
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cau</placeTerm>
  #           </place>
  #           <dateIssued encoding="marc">2020</dateIssued>
  #           <copyrightDate encoding="marc">2020</copyrightDate>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo eventType="publication">
  #           <place>
  #             <placeTerm type="text">[Stanford, Calif.]</placeTerm>
  #           </place>
  #           <publisher>[Stanford University]</publisher>
  #           <dateIssued>2020</dateIssued>
  #         </originInfo>
  #         <originInfo eventType="copyright notice">
  #           <copyrightDate>©2020</copyrightDate>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cau</placeTerm>
  #           </place>
  #           <dateIssued encoding="marc">2020</dateIssued>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo eventType="publication">
  #           <place>
  #             <placeTerm type="text">[Stanford, Calif.]</placeTerm>
  #           </place>
  #           <publisher>[Stanford University]</publisher>
  #           <dateIssued>2020</dateIssued>
  #         </originInfo>
  #         <originInfo eventType="copyright">
  #           <copyrightDate encoding="marc">2020</copyrightDate>
  #         </originInfo>
  #         <originInfo eventType="copyright notice">
  #           <copyrightDate>©2020</copyrightDate>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'publication',
  #             location: [
  #               {
  #                 code: 'cau',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               }
  #             ],
  #             date: [
  #               {
  #                 value: '2020',
  #                 encoding: {
  #                   code: 'marc'
  #                 }
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'issuance',
  #                 value: 'monographic',
  #                 source: {
  #                   value: 'MODS issuance terms'
  #                 }
  #               }
  #             ]
  #           },
  #           {
  #             type: 'copyright',
  #             date: [
  #               {
  #                 value: '2020',
  #                 encoding: {
  #                   code: 'marc'
  #                 }
  #               }
  #             ]
  #           },
  #           {
  #             type: 'publication',
  #             location: [
  #               {
  #                 value: '[Stanford, Calif.]'
  #               }
  #             ],
  #             contributor: [
  #               {
  #                 name: [
  #                   {
  #                     value: '[Stanford University]'
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
  #             date: [
  #               {
  #                 value: '2020'
  #               }
  #             ]
  #           },
  #           {
  #             type: 'copyright',
  #             note: [
  #               {
  #                 value: '©2020',
  #                 type: 'copyright statement'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # specs added by devs below

  # describe 'parallel values with example adapted from hn285fy7937' do
  #   # example adapted from hn285fy7937 after normalization
  #
  #   xit 'to be implemented: updated warning message' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo altRepGroup="1" eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Chengdu</placeTerm>
  #           </place>
  #           <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
  #           <dateIssued>2005</dateIssued>
  #           <edition>Di 1 ban.</edition>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo altRepGroup="1" eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
  #           </place>
  #           <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
  #           <dateIssued>2005</dateIssued>
  #           <edition>[Di 1 ban in Chinese]</edition>
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
  #             location: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Chengdu'
  #                   },
  #                   {
  #                     value: '[Chengdu in Chinese]'
  #                   }
  #                 ]
  #               },
  #               {
  #                 code: 'cc',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               }
  #             ],
  #             contributor: [
  #               {
  #                 type: 'organization',
  #                 name: [
  #                   {
  #                     parallelValue: [
  #                       {
  #                         value: 'Sichuan chu ban ji tuan, Sichuan wen yi chu ban she'
  #                       },
  #                       {
  #                         value: '[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]'
  #                       }
  #                     ]
  #                   }
  #                 ],
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
  #             date: [
  #               {
  #                 value: '2005'
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'edition',
  #                 parallelValue: [
  #                   {
  #                     value: 'Di 1 ban.'
  #                   },
  #                   {
  #                     value: '[Di 1 ban in Chinese]'
  #                   }
  #                 ]
  #               },
  #               {
  #                 type: 'issuance',
  #                 value: 'monographic',
  #                 source: {
  #                   value: 'MODS issuance terms'
  #                 }
  #
  #               }
  #
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #
  #     let(:warnings) { [Notification.new(msg: 'altRepGroup missing lang/script')] }
  #   end
  # end

  # describe 'parallel values - originInfo with additional elements in the second position' do
  #   # example adapted from bh212vz9239 in different order
  #
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo altRepGroup="1">
  #           <place>
  #             <placeTerm type="text">Guangdong in Chinese</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
  #         </originInfo>
  #         <originInfo altRepGroup="1">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #       XML
  #     end
  #
  #     # all parallel elements in both originInfo elementseventType
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo altRepGroup="1" eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong in Chinese</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
  #           <issuance>monographic</issuance>
  #         </originInfo>
  #         <originInfo altRepGroup="1" eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #           </place>
  #           <place>
  #             <placeTerm type="text">Guangdong</placeTerm>
  #           </place>
  #           <publisher>Guangdong lu jun ce liang ju</publisher>
  #           <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
  #           <dateIssued encoding="marc" point="start">1922</dateIssued>
  #           <dateIssued encoding="marc" point="end">1929</dateIssued>
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
  #             location: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Guangdong in Chinese'
  #                   },
  #                   {
  #                     value: 'Guangdong'
  #                   }
  #                 ]
  #               },
  #               {
  #                 code: 'cc',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               }
  #             ],
  #             contributor: [
  #               {
  #                 type: 'organization',
  #                 name: [
  #                   {
  #                     parallelValue: [
  #                       {
  #                         value: 'Guangdong lu jun ce liang ju in Chinese'
  #                       },
  #                       {
  #                         value: 'Guangdong lu jun ce liang ju'
  #                       }
  #                     ]
  #                   }
  #                 ],
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
  #             date: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Minguo 11-18 [1922-1929] in Chinese'
  #                   },
  #                   {
  #                     value: 'Minguo 11-18 [1922-1929]'
  #                   }
  #                 ]
  #               },
  #               {
  #                 structuredValue: [
  #                   {
  #                     value: '1922',
  #                     type: 'start'
  #                   },
  #                   {
  #                     value: '1929',
  #                     type: 'end'
  #                   }
  #                 ],
  #                 encoding: {
  #                   code: 'marc'
  #                 }
  #               }
  #             ],
  #             note: [
  #               {
  #                 type: 'issuance',
  #                 value: 'monographic',
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

  # describe 'parallel value - with second originInfo that would not get an event type' do
  #   # from druid:mm706hr7414
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #           <originInfo altRepGroup="1">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">is</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">Tel-Aviv</placeTerm>
  #             </place>
  #             <publisher>A. Shṭibel</publisher>
  #             <dateIssued>1939</dateIssued>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #           <originInfo script="" altRepGroup="1">
  #             <place>
  #               <placeTerm type="text">תל־אביב :</placeTerm>
  #             </place>
  #             <publisher>ש. שטיבל,1939.</publisher>
  #         </originInfo>
  #       XML
  #     end
  #
  #     # add eventType, all elements must be present in all group members, remove empty script attrib
  #     let(:roundtrip_mods) do
  #       <<~XML
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">is</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">Tel-Aviv</placeTerm>
  #             </place>
  #             <publisher>A. Shṭibel</publisher>
  #             <dateIssued>1939</dateIssued>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">is</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">תל־אביב :</placeTerm>
  #             </place>
  #             <publisher>ש. שטיבל,1939.</publisher>
  #             <dateIssued>1939</dateIssued>
  #             <issuance>monographic</issuance>
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
  #                 value: '1939'
  #               }
  #             ],
  #             location: [
  #               {
  #                 parallelValue: [
  #                   {
  #                     value: 'Tel-Aviv'
  #                   },
  #                   {
  #                     value: 'תל־אביב :'
  #                   }
  #                 ]
  #               },
  #               {
  #                 source: {
  #                   code: 'marccountry'
  #                 },
  #                 code: 'is'
  #               }
  #             ],
  #             note: [
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
  #                     parallelValue: [
  #                       {
  #                         value: 'A. Shṭibel'
  #                       },
  #                       {
  #                         value: 'ש. שטיבל,1939.'
  #                       }
  #                     ]
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
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # context 'when eventType matches date type "distribution"' do
  #   # bad data mapping (?)
  #   # NOTE: cocina -> MODS mapping
  #   xit 'to be mapped?:  MODS maps back to event type publication' do
  #     # NOTE: contributor role is distributor, not publisher
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'distribution',
  #             contributor: [
  #               {
  #                 name: [
  #                   {
  #                     value: 'For sale by the Superintendent of Documents, U.S. Government Publishing Office'
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
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="distribution">
  #           <place>
  #             <placeTerm type="text">Washington, DC</placeTerm>
  #           </place>
  #           <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
  #           <dateOther/>
  #         </originInfo>
  #       XML
  #     end
  #   end
  # end

  # context 'with an originInfo that has place and publisher, but no date (type publication)' do
  #   # From druid:bs861pk7886
  #   # bad data mapping
  #
  #   it_behaves_like 'MODS cocina mapping' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo>
  #           <place>
  #             <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names"
  #               valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
  #           </place>
  #           <publisher>Stanford University. Department of Geophysics</publisher>
  #         </originInfo>
  #       XML
  #     end
  #
  #     # add eventType and trailing slash on authorityURI
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <place>
  #             <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/"
  #               valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
  #           </place>
  #           <publisher>Stanford University. Department of Geophysics</publisher>
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
  #                     value: 'Stanford University. Department of Geophysics'
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
  #                 uri: 'http://id.loc.gov/authorities/names/n50046557',
  #                 source: {
  #                   code: 'marccountry',
  #                   uri: 'http://id.loc.gov/authorities/names/'
  #                 },
  #                 value: 'Stanford (Calif.)'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  # context 'with multiple events and missing event type' do
  #   # NOTE: cocina -> MODS mapping
  #   xit 'to be implemented: note that MODS is not correctly mapping to cocina' do
      # FIXME:  3 events - the second date splits to event without type, and location gets type publication
      # Updated by Arcadia to match current model, replaces above specification

      # Naomi notes the roundtrip_cocina here is exactly the same as above
      # let(:roundtrip_cocina) do
      #   {
      #     event: [
      #       {
      #         type: 'production',
      #         date: [
      #           {
      #             value: '1899'
      #           }
      #         ],
      #         location: [
      #           {
      #             value: 'York'
      #           }
      #         ]
      #       },
      #       {
      #         location: [
      #           {
      #             value: 'London'
      #           }
      #         ],
      #         date: [
      #           {
      #             value: '1901'
      #           }
      #         ]
      #       }
      #     ]
      #   }
      # end
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'production',
  #             date: [
  #               {
  #                 value: '1899'
  #               }
  #             ],
  #             location: [
  #               {
  #                 value: 'York'
  #               }
  #             ]
  #           },
  #           {
  #             date: [
  #               {
  #                 value: '1901'
  #               }
  #             ],
  #             location: [
  #               {
  #                 value: 'London'
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="production">
  #           <dateCreated>1899</dateCreated>
  #           <place>
  #             <placeTerm type="text">York</placeTerm>
  #           </place>
  #         </originInfo>
  #         <originInfo>
  #           <dateOther>1901</dateOther>
  #           <place>
  #             <placeTerm type="text">London</placeTerm>
  #           </place>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:warnings) { [Notification.new(msg: 'Undetermined event type')] }
  #   end
  # end

  # describe 'eventType consistent for roundtrip' do
  #   context 'when dateCreated and dateIssued in eventType publication it splits' do
  #     # based on kq506ht3416
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="publication">
  #             <publisher>Fontana/Collins</publisher>
  #             <dateIssued>1978</dateIssued>
  #             <dateCreated>(1981 printing)</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # dateCreated split into separate originInfo
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo eventType="publication">
  #             <publisher>Fontana/Collins</publisher>
  #             <dateIssued>1978</dateIssued>
  #           </originInfo>
  #           <originInfo eventType="production">
  #             <dateCreated>(1981 printing)</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   value: '(1981 printing)'
  #                 }
  #               ]
  #             },
  #             {
  #               type: 'publication',
  #               date: [
  #                 {
  #                   value: '1978'
  #                 }
  #               ],
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'Fontana/Collins'
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
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when dateCreated as point with 2 elements in same originInfo as dateIssued, dateIssued splits' do
  #     # based on nn349sf6895, rx731vv3403
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Place of creation" eventType="publication">
  #             <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
  #             <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
  #             <dateIssued>1887</dateIssued>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # split into separate originInfo
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo displayLabel="Place of creation" eventType="publication">
  #             <dateIssued>1887</dateIssued>
  #           </originInfo>
  #           <originInfo displayLabel="Place of creation" eventType="production">
  #             <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
  #             <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   structuredValue: [
  #                     {
  #                       type: 'start',
  #                       value: '1872',
  #                       status: 'primary'
  #                     },
  #                     {
  #                       type: 'end',
  #                       value: '1885'
  #                     }
  #                   ],
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   }
  #                 }
  #               ],
  #               displayLabel: 'Place of creation'
  #             },
  #             {
  #               type: 'publication',
  #               date: [
  #                 {
  #                   value: '1887'
  #                 }
  #               ],
  #               displayLabel: 'Place of creation'
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when dateCreated and dateIssued in same originInfo in altRepGroup' do
  #     # based on dz647hf2887, db936hw1344
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization needs to split up originInfo'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <publisher>Tairyūsha</publisher>
  #             <dateIssued>Shōwa 52 [1977]</dateIssued>
  #             <dateCreated>(1978 printing)</dateCreated>
  #           </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <publisher>泰流社</publisher>
  #             <dateIssued>昭和 52 [1977]</dateIssued>
  #             <dateCreated>(1978 printing)</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # splits dateCreated into separate originInfo
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo eventType="production">
  #              <dateCreated>(1978 printing)</dateCreated>
  #            </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <publisher>Tairyūsha</publisher>
  #             <dateIssued>Shōwa 52 [1977]</dateIssued>
  #           </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <publisher>泰流社</publisher>
  #             <dateIssued>昭和 52 [1977]</dateIssued>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   value: '(1978 printing)'
  #                 }
  #               ]
  #             },
  #             {
  #               type: 'publication',
  #               date: [
  #                 {
  #                   parallelValue: [
  #                     {
  #                       value: 'Shōwa 52 [1977]'
  #                     },
  #                     {
  #                       value: '昭和 52 [1977]'
  #                     }
  #                   ]
  #                 }
  #               ],
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       parallelValue: [
  #                         {
  #                           value: 'Tairyūsha'
  #                         },
  #                         {
  #                           value: '泰流社'
  #                         }
  #                       ]
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
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when dateCreated and dateCaptured in same originInfo' do
  #     # based on sc262hs3556
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization must split originInfo'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo>
  #             <dateCreated keyDate="yes" encoding="w3cdtf">2018-08-21</dateCreated>
  #             <dateCaptured encoding="w3cdtf">2018-08-30</dateCaptured>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # dateCreated split into separate originInfo
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo eventType='production'>
  #             <dateCreated keyDate="yes" encoding="w3cdtf">2018-08-21</dateCreated>
  #           </originInfo>
  #           <originInfo eventType='capture'>
  #             <dateCaptured encoding="w3cdtf">2018-08-30</dateCaptured>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   value: '2018-08-21',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ]
  #             },
  #             {
  #               type: 'capture',
  #               date: [
  #                 {
  #                   value: '2018-08-30',
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
  #   context 'when dateCreated and dateOther and eventType production' do
  #     # based on dg875gq3366
  #     it_behaves_like 'MODS cocina mapping' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="something" eventType="production">
  #             <dateCreated keyDate="yes" encoding="w3cdtf">1905</dateCreated>
  #             <dateOther qualifier="approximate" point="end">1925</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # splits dateCreated into separate originInfo; dateOther becomes dateCreated
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo displayLabel="something" eventType="production">
  #             <dateCreated keyDate="yes" encoding="w3cdtf">1905</dateCreated>
  #           </originInfo>
  #           <originInfo displayLabel="something" eventType="production">
  #             <dateCreated qualifier="approximate" point="end">1925</dateCreated>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   value: '1905',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   },
  #                   status: 'primary'
  #                 }
  #               ],
  #               displayLabel: 'something'
  #             },
  #             {
  #               type: 'creation',
  #               date: [
  #                 {
  #                   qualifier: 'approximate',
  #                   type: 'end',
  #                   value: '1925'
  #                 }
  #               ],
  #               displayLabel: 'something'
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when dateOther with type manufacture and publisher element it splits' do
  #     # based on yd527ky9095, zw971gd0220
  #     # it_behaves_like 'MODS cocina mapping' do
  #     xit 'to be implemented: eventType manufacture; also originInfo normalization needs to split up originInfo' do
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="manufacturer">
  #             <publisher>J. Jennings Lith. 326 Sansome St.,</publisher>
  #             <dateOther type="manufacture">1873.</dateOther>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # splits into 2; removes trailing period in date
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo displayLabel="manufacturer" eventType="manufacture">
  #             <dateOther type="manufacture">1873</dateOther>
  #           </originInfo>
  #           <originInfo eventType="publication">
  #             <publisher>J. Jennings Lith. 326 Sansome St.,</publisher>
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
  #                   note: [
  #                     {
  #                       value: 'manufacture',
  #                       type: 'date type'
  #                     }
  #                   ],
  #                   value: '1873'
  #                 }
  #               ],
  #               displayLabel: 'manufacturer'
  #             },
  #             {
  #               type: 'publication',
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'J. Jennings Lith. 326 Sansome St.,'
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
  #               ]
  #               # location: [
  #               #   {
  #               #     value: "S. F. [San Francisco] :"
  #               #   }
  #               # ]
  #             }
  #           ]
  #         }
  #       end
  #
  #       let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
  #     end
  #   end
  #
  #   context 'when copyrightDate and issuance in single originInfo' do
  #     # based on kc487sz0076
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization needs to split up originInfo'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="copyright">
  #             <copyrightDate encoding="marc">2005</copyrightDate>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # copyrightDate splits from issuance
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo eventType="copyright">
  #             <copyrightDate encoding="marc">2005</copyrightDate>
  #           </originInfo>
  #           <originInfo eventType="publication">
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'copyright',
  #               date: [
  #                 {
  #                   value: '2005',
  #                   encoding: {
  #                     code: 'marc'
  #                   }
  #                 }
  #               ]
  #             },
  #             {
  #               type: 'publication',
  #               note: [
  #                 {
  #                   source: {
  #                     value: 'MODS issuance terms'
  #                   },
  #                   type: 'issuance',
  #                   value: 'monographic'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when eventType manufacture with publisher element' do
  #     # based on jz402xk5530
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization must change eventType'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="manufacturer" eventType="manufacture">
  #             <publisher>Lithographed in the Reproduction Branch, SSU</publisher>
  #             <dateOther/>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # eventType becomes publication
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo displayLabel="manufacturer" eventType="publication">
  #             <publisher>Lithographed in the Reproduction Branch, SSU</publisher>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'publication',
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'Lithographed in the Reproduction Branch, SSU'
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
  #               displayLabel: 'manufacturer'
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when eventType distribution with publisher element' do
  #     # based on rm699mr9758, xy550sj6776
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization must change eventType'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo eventType="distribution">
  #             <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # eventType becomes publication
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo eventType="publication">
  #             <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'publication',
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       value: 'For sale by the Superintendent of Documents, U.S. Government Publishing Office'
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
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  #
  #   context 'when dateCaptured and publisher elements it splits' do
  #     context 'with eventType' do
  #       # based on rn990mm7360
  #       it_behaves_like 'MODS cocina mapping' do
  #         xit 'to be implemented: originInfo normalization must split originInfo'
  #         let(:skip_normalization) { true }
  #
  #         let(:mods) do
  #           <<~XML
  #             <originInfo eventType="capture">
  #               <publisher>California. State Department of Education. Office of Curriculum Services</publisher>
  #               <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
  #               <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
  #             </originInfo>
  #           XML
  #         end
  #
  #         # split capture and publication
  #         let(:roundtrip_mods) do
  #           <<~XML
  #             <originInfo eventType="capture">
  #               <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
  #               <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
  #             </originInfo>
  #             <originInfo eventType="publication">
  #               <publisher>California. State Department of Education. Office of Curriculum Services</publisher>
  #             </originInfo>
  #           XML
  #         end
  #
  #         let(:cocina) do
  #           {
  #             event: [
  #               {
  #                 type: 'capture',
  #                 date: [
  #                   {
  #                     structuredValue: [
  #                       {
  #                         type: 'start',
  #                         value: '2007-12-10',
  #                         status: 'primary'
  #                       },
  #                       {
  #                         type: 'end',
  #                         value: '2011-01-24'
  #                       }
  #                     ],
  #                     encoding: {
  #                       code: 'iso8601'
  #                     }
  #                   }
  #                 ]
  #               },
  #               {
  #                 type: 'publication',
  #                 contributor: [
  #                   {
  #                     name: [
  #                       {
  #                         value: 'California. State Department of Education. Office of Curriculum Services'
  #                       }
  #                     ],
  #                     type: 'organization',
  #                     role: [
  #                       {
  #                         value: 'publisher',
  #                         code: 'pbl',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                         source: {
  #                           code: 'marcrelator',
  #                           uri: 'http://id.loc.gov/vocabulary/relators/'
  #                         }
  #                       }
  #                     ]
  #                   }
  #                 ]
  #               }
  #             ]
  #           }
  #         end
  #       end
  #     end
  #
  #     context 'without eventType' do
  #       # based on bm023zm8062
  #       it_behaves_like 'MODS cocina mapping' do
  #         xit 'to be implemented: originInfo normalization must split originInfo'
  #         let(:skip_normalization) { true }
  #
  #         let(:mods) do
  #           <<~XML
  #             <originInfo>
  #               <publisher>Dept. of Defense</publisher>
  #               <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
  #               <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
  #             </originInfo>
  #           XML
  #         end
  #
  #         # split capture and publication
  #         let(:roundtrip_mods) do
  #           <<~XML
  #             <originInfo eventType="capture">
  #               <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
  #               <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
  #             </originInfo>
  #             <originInfo eventType="publication">
  #               <publisher>Dept. of Defense</publisher>
  #             </originInfo>
  #           XML
  #         end
  #
  #         let(:cocina) do
  #           {
  #             event: [
  #               {
  #                 type: 'capture',
  #                 date: [
  #                   {
  #                     structuredValue: [
  #                       {
  #                         type: 'start',
  #                         value: '2007-12-10',
  #                         status: 'primary'
  #                       },
  #                       {
  #                         type: 'end',
  #                         value: '2011-01-24'
  #                       }
  #                     ],
  #                     encoding: {
  #                       code: 'iso8601'
  #                     }
  #                   }
  #                 ]
  #               },
  #               {
  #                 type: 'publication',
  #                 contributor: [
  #                   {
  #                     name: [
  #                       {
  #                         value: 'Dept. of Defense'
  #                       }
  #                     ],
  #                     type: 'organization',
  #                     role: [
  #                       {
  #                         value: 'publisher',
  #                         code: 'pbl',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                         source: {
  #                           code: 'marcrelator',
  #                           uri: 'http://id.loc.gov/vocabulary/relators/'
  #                         }
  #                       }
  #                     ]
  #                   }
  #                 ]
  #               }
  #             ]
  #           }
  #         end
  #       end
  #     end
  #   end
  #
  #   context 'when eventType with copyrightDate and place it splits' do
  #     context 'with eventType copyright' do
  #       # based on vw478nk8207
  #       it_behaves_like 'MODS cocina mapping' do
  #         xit 'to be implemented: originInfo normalization must split originInfo'
  #         let(:skip_normalization) { true }
  #
  #         let(:mods) do
  #           <<~XML
  #             <originInfo displayLabel="Place of creation" eventType="copyright">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #               <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
  #               <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
  #             </originInfo>
  #           XML
  #         end
  #
  #         # split into two elements
  #         let(:roundtrip_mods) do
  #           <<~XML
  #             <originInfo displayLabel="Place of creation" eventType="copyright">
  #               <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
  #               <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
  #             </originInfo>
  #             <originInfo displayLabel="Place of creation" eventType="publication">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #             </originInfo>
  #           XML
  #         end
  #
  #         let(:cocina) do
  #           {
  #             event: [
  #               {
  #                 type: 'copyright',
  #                 date: [
  #                   {
  #                     structuredValue: [
  #                       {
  #                         type: 'start',
  #                         value: '1970',
  #                         status: 'primary'
  #                       },
  #                       {
  #                         type: 'end',
  #                         value: '1974'
  #                       }
  #                     ],
  #                     qualifier: 'approximate',
  #                     encoding: {
  #                       code: 'w3cdtf'
  #                     }
  #                   }
  #                 ],
  #                 displayLabel: 'Place of creation'
  #               },
  #               {
  #                 type: 'publication',
  #                 location: [
  #                   {
  #                     value: 'San Francisco (Calif.)'
  #                   }
  #                 ],
  #                 displayLabel: 'Place of creation'
  #               }
  #             ]
  #           }
  #         end
  #       end
  #     end
  #
  #     context 'with eventType production' do
  #       # based on nd217pz1557
  #       it_behaves_like 'MODS cocina mapping' do
  #         xit 'to be implemented: originInfo normalization must split originInfo'
  #         let(:skip_normalization) { true }
  #
  #         let(:mods) do
  #           <<~XML
  #             <originInfo displayLabel="Place of creation" eventType="production">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #               <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1960</copyrightDate>
  #               <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1965</copyrightDate>
  #             </originInfo>
  #           XML
  #         end
  #
  #         # split into two elements
  #         let(:roundtrip_mods) do
  #           <<~XML
  #             <originInfo displayLabel="Place of creation" eventType="copyright">
  #               <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1960</copyrightDate>
  #               <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1965</copyrightDate>
  #             </originInfo>
  #             <originInfo displayLabel="Place of creation" eventType="publication">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #             </originInfo>
  #           XML
  #         end
  #
  #         let(:cocina) do
  #           {
  #             event: [
  #               {
  #                 type: 'copyright',
  #                 date: [
  #                   {
  #                     structuredValue: [
  #                       {
  #                         type: 'start',
  #                         value: '1960',
  #                         status: 'primary'
  #                       },
  #                       {
  #                         type: 'end',
  #                         value: '1965'
  #                       }
  #                     ],
  #                     qualifier: 'approximate',
  #                     encoding: {
  #                       code: 'w3cdtf'
  #                     }
  #                   }
  #                 ],
  #                 displayLabel: 'Place of creation'
  #               },
  #               {
  #                 type: 'publication',
  #                 location: [
  #                   {
  #                     value: 'San Francisco (Calif.)'
  #                   }
  #                 ],
  #                 displayLabel: 'Place of creation'
  #               }
  #             ]
  #           }
  #         end
  #       end
  #     end
  #
  #     context 'with eventType copyright and publisher' do
  #       # based on mr888cv5629
  #       it_behaves_like 'MODS cocina mapping' do
  #         xit 'to be implemented: originInfo normalization must split originInfo'
  #         let(:skip_normalization) { true }
  #
  #         let(:mods) do
  #           <<~XML
  #             <originInfo eventType="copyright">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #               <publisher>San Francisco Examiner</publisher>
  #               <copyrightDate keyDate="yes" encoding="w3cdtf">1901</copyrightDate>
  #             </originInfo>
  #           XML
  #         end
  #
  #         # split into two elements
  #         let(:roundtrip_mods) do
  #           <<~XML
  #             <originInfo eventType="copyright">
  #               <copyrightDate keyDate="yes" encoding="w3cdtf">1901</copyrightDate>
  #             </originInfo>
  #             <originInfo eventType="publication">
  #               <place>
  #                 <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #               </place>
  #               <publisher>San Francisco Examiner</publisher>
  #             </originInfo>
  #           XML
  #         end
  #
  #         let(:cocina) do
  #           {
  #             event: [
  #               {
  #                 type: 'copyright',
  #                 date: [
  #                   {
  #                     value: '1901',
  #                     status: 'primary',
  #                     encoding: {
  #                       code: 'w3cdtf'
  #                     }
  #                   }
  #                 ]
  #               },
  #               {
  #                 type: 'publication',
  #                 location: [
  #                   {
  #                     value: 'San Francisco (Calif.)'
  #                   }
  #                 ],
  #                 contributor: [
  #                   {
  #                     name: [
  #                       value: 'San Francisco Examiner'
  #                     ],
  #                     type: 'organization',
  #                     role: [
  #                       {
  #                         value: 'publisher',
  #                         code: 'pbl',
  #                         uri: 'http://id.loc.gov/vocabulary/relators/pbl',
  #                         source: {
  #                           code: 'marcrelator',
  #                           uri: 'http://id.loc.gov/vocabulary/relators/'
  #                         }
  #                       }
  #                     ]
  #                   }
  #                 ]
  #               }
  #             ]
  #           }
  #         end
  #       end
  #     end
  #   end
  #
  #   context 'when eventType production with copyrightDate and place it splits' do
  #     # based on vw478nk8207
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: originInfo normalization must split originInfo and change eventType'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo displayLabel="Place of creation" eventType="production">
  #             <place>
  #               <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #             </place>
  #             <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
  #             <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # split into two elements and 'production' is updated to copyright
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo displayLabel="Place of creation" eventType="copyright">
  #             <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
  #             <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
  #           </originInfo>
  #           <originInfo displayLabel="Place of creation" eventType="publication">
  #             <place>
  #               <placeTerm type="text">San Francisco (Calif.)</placeTerm>
  #             </place>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'copyright',
  #               date: [
  #                 {
  #                   structuredValue: [
  #                     {
  #                       type: 'start',
  #                       value: '1970',
  #                       status: 'primary'
  #                     },
  #                     {
  #                       type: 'end',
  #                       value: '1974'
  #                     }
  #                   ],
  #                   qualifier: 'approximate',
  #                   encoding: {
  #                     code: 'w3cdtf'
  #                   }
  #                 }
  #               ],
  #               displayLabel: 'Place of creation'
  #             },
  #             {
  #               type: 'publication',
  #               location: [
  #                 {
  #                   value: 'San Francisco (Calif.)'
  #                 }
  #               ],
  #               displayLabel: 'Place of creation'
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end

  #   context 'when altRepGroup subelements are missing from one of the elements' do
  #     # based on xj114vt0439
  #     it_behaves_like 'MODS cocina mapping' do
  #       xit 'to be implemented: normalization must ensure all elements in altRepGroup are matched'
  #       let(:skip_normalization) { true }
  #
  #       let(:mods) do
  #         <<~XML
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">Shanghai</placeTerm>
  #             </place>
  #             <publisher>Shanghai shu dian chu ban</publisher>
  #             <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
  #             <dateIssued>1992</dateIssued>
  #             <edition>Di 1 ban.</edition>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">上海:上海书店出版：</placeTerm>
  #             </place>
  #             <publisher>新华书店上海发行所发行,</publisher>
  #             <dateIssued>1992</dateIssued>
  #             <edition>第1版.</edition>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #         XML
  #       end
  #
  #       # add second publisher to second originInfo so they match.
  #       let(:roundtrip_mods) do
  #         <<~XML
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">Shanghai</placeTerm>
  #             </place>
  #             <publisher>Shanghai shu dian chu ban</publisher>
  #             <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
  #             <dateIssued>1992</dateIssued>
  #             <edition>Di 1 ban.</edition>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #           <originInfo altRepGroup="1" eventType="publication">
  #             <place>
  #               <placeTerm type="code" authority="marccountry">cc</placeTerm>
  #             </place>
  #             <place>
  #               <placeTerm type="text">上海:上海书店出版：</placeTerm>
  #             </place>
  #             <publisher>新华书店上海发行所发行,</publisher>
  #             <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
  #             <dateIssued>1992</dateIssued>
  #             <edition>第1版.</edition>
  #             <issuance>monographic</issuance>
  #           </originInfo>
  #         XML
  #       end
  #
  #       let(:cocina) do
  #         {
  #           event: [
  #             {
  #               type: 'publication',
  #               date: [
  #                 {
  #                   value: '1992'
  #                 }
  #               ],
  #               note: [
  #                 {
  #                   type: 'edition',
  #                   parallelValue: [
  #                     {
  #                       value: 'Di 1 ban.'
  #                     },
  #                     {
  #                       value: '第1版.'
  #                     }
  #                   ]
  #                 },
  #                 {
  #                   source: {
  #                     value: 'MODS issuance terms'
  #                   },
  #                   type: 'issuance',
  #                   value: 'monographic'
  #                 }
  #               ],
  #               contributor: [
  #                 {
  #                   name: [
  #                     {
  #                       parallelValue: [
  #                         {
  #                           value: 'Shanghai shu dian chu ban'
  #                         },
  #                         {
  #                           value: '新华书店上海发行所发行,'
  #                         }
  #                       ]
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
  #                 },
  #                 {
  #                   name: [
  #                     {
  #                       value: 'Xin hua shu dian Shanghai fa xing suo fa xing'
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
  #                   parallelValue: [
  #                     {
  #                       value: 'Shanghai'
  #                     },
  #                     {
  #                       value: '上海:上海书店出版：'
  #                     }
  #                   ]
  #                 },
  #                 {
  #                   source: {
  #                     code: 'marccountry'
  #                   },
  #                   code: 'cc'
  #                 }
  #               ]
  #             }
  #           ]
  #         }
  #       end
  #     end
  #   end
  # end

  # context 'with displayLabel, it should map to all events generated' do
  #   # based on jj635pq5167
  #   # TODO:  see also origin_info_normalizer for same record if eventTypes date flavor changes on roundtrip
  #   xit 'to be mapped: should dateIssued become dateOther on roundtrip? what should eventTypes be?' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo displayLabel="Place of creation" eventType="production">
  #           <place>
  #             <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names"
  #               valueURI="http://id.loc.gov/authorities/names/n78095520">xxu</placeTerm>
  #             <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names"
  #               valueURI="http://id.loc.gov/authorities/names/n78095520">Philadelphia</placeTerm>
  #           </place>
  #           <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
  #           <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
  #           <dateIssued>1887</dateIssued>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:roundtrip_mods) do
  #       <<~XML
  #         <originInfo displayLabel="Place of creation" eventType="production">
  #           <place>
  #             <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/"
  #               valueURI="http://id.loc.gov/authorities/names/n78095520">xxu</placeTerm>
  #             <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/"
  #               valueURI="http://id.loc.gov/authorities/names/n78095520">Philadelphia</placeTerm>
  #           </place>
  #           <dateIssued>1887</dateIssued>
  #         </originInfo>
  #         <originInfo displayLabel="Place of creation" eventType="creation">
  #           <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
  #           <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'production',
  #             date: [
  #               {
  #                 value: '1887'
  #               }
  #             ],
  #             location: [
  #               {
  #                 uri: 'http://id.loc.gov/authorities/names/n78095520',
  #                 source: {
  #                   code: 'marccountry',
  #                   uri: 'http://id.loc.gov/authorities/names/'
  #                 },
  #                 value: 'Philadelphia',
  #                 code: 'xxu'
  #               }
  #             ],
  #             displayLabel: 'Place of creation'
  #           },
  #           {
  #             type: 'creation',
  #             date: [
  #               {
  #                 structuredValue: [
  #                   {
  #                     type: 'start',
  #                     value: '1872',
  #                     status: 'primary'
  #                   },
  #                   {
  #                     type: 'end',
  #                     value: '1885'
  #                   }
  #                 ],
  #                 encoding: {
  #                   code: 'w3cdtf'
  #                 }
  #               }
  #             ],
  #             displayLabel: 'Place of creation'
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end
end
