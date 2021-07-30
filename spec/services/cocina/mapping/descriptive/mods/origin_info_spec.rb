# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings' do
  describe 'Edition' do
    it_behaves_like 'MODS cocina mapping' do
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
    it_behaves_like 'MODS cocina mapping' do
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
    it_behaves_like 'MODS cocina mapping' do
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
    it_behaves_like 'MODS cocina mapping' do
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
    # "copyright notice" maps to event.note
    it_behaves_like 'MODS cocina mapping' do
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
                  ],
                  type: 'organization'
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
                      ],
                      type: 'organization'
                    }
                  ],
                  date: [
                    {
                      value: 'Heisei 8 [1996]',
                      type: 'publication'
                    },
                    {
                      value: '1996',
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
                      ],
                      type: 'organization'
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
    it_behaves_like 'MODS cocina mapping' do
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production" displayLabel="Original" lang="eng" script="Latn" altRepGroup="1">
            <dateCreated keyDate="yes" encoding="w3cdtf">1999-09-09</dateCreated>
            <place>
              <placeTerm type="text" authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n79076156">Moscow</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="production" displayLabel="Original" lang="rus" script="Cyrl" altRepGroup="1">
            <place>
              <placeTerm type="text">Москва</placeTerm>
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
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
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
                  note: [
                    {
                      type: 'edition',
                      value: 'First edition'
                    }
                  ]
                },
                {
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
                      type: 'edition',
                      value: 'Первое издание'
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
    it_behaves_like 'MODS cocina mapping' do
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
                      type: 'edition',
                      value: 'First edition'
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
                      type: 'edition',
                      value: 'Первое издание'
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
                      ],
                      type: 'organization'
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
                      value: ' 成都'
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
                      ],
                      type: 'organization'
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
    it_behaves_like 'MODS cocina mapping' do
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
                      type: 'edition',
                      value: 'First edition'
                    }
                  ]
                },
                {
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
                      type: 'edition',
                      value: 'Первое издание'
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
    it_behaves_like 'MODS cocina mapping' do
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
    it_behaves_like 'MODS cocina mapping' do
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
                      ],
                      type: 'organization'
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
                      ],
                      type: 'organization'
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

  context 'when altRepGroup script values match' do
    # based on rz633ck7860
    it_behaves_like 'MODS cocina mapping' do
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
                      ],
                      type: 'organization'
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
                      },
                      type: 'publication'
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
                      ],
                      type: 'organization'
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
                      },
                      type: 'publication'
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

      # NOTE: it does NOT warn as this is a valid pairing of altRepGroup
    end
  end

  # specs added by devs below

  context 'when originInfo / event is various flavors of empty/missing' do
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

    context 'when MODS is a bunch of nothing based on actual record' do
      # based on qy796rh6653
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo eventType="production">
              <place>
                <placeTerm type="text"/>
              </place>
              <publisher/>
              <dateOther type="production"/>
            </originInfo>
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

  context 'when two originInfos, one empty' do
    # based on qy796rh6653
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm authority="marccountry" type="code">xx</placeTerm>
            </place>
            <dateCreated encoding="marc">1990</dateCreated>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="production">
            <place>
              <placeTerm type="text"/>
            </place>
            <publisher/>
            <dateOther type="production"/>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm authority="marccountry" type="code">xx</placeTerm>
            </place>
            <dateCreated encoding="marc">1990</dateCreated>
            <issuance>monographic</issuance>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              location: [
                {
                  code: 'xx',
                  source: {
                    code: 'marccountry'
                  }
                }
              ],
              date: [
                {
                  value: '1990',
                  type: 'creation',
                  encoding: {
                    code: 'marc'
                  }
                }
              ],
              note: [
                type: 'issuance',
                value: 'monographic',
                source: {
                  value: 'MODS issuance terms'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'unpaired altRepGroup' do
    # based on yz694pz8086

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo script="Latn">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <dateIssued encoding="marc" point="start">1932</dateIssued>
            <dateIssued encoding="marc" point="end">1935</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo displayLabel="publisher" altRepGroup="04" script="Latn">
            <place>
              <placeTerm>[Tokyo] :</placeTerm>
            </place>
            <publisher>Dainihon Teikoku Rikuchi Sokuryōbu,</publisher>
            <dateIssued>Shōwa 7-10 [1932-1935]</dateIssued>
          </originInfo>
        XML
      end

      # second originInfo: legacy displayLabel becomes eventType; unmatched altRepGroup removed; placeTerm type text
      let(:roundtrip_mods) do
        <<~XML
          <originInfo script="Latn">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <dateIssued encoding="marc" point="start">1932</dateIssued>
            <dateIssued encoding="marc" point="end">1935</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication" script="Latn">
            <place>
              <placeTerm type="text">[Tokyo] :</placeTerm>
            </place>
            <publisher>Dainihon Teikoku Rikuchi Sokuryōbu,</publisher>
            <dateIssued>Shōwa 7-10 [1932-1935]</dateIssued>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
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
                }
              ],
              date: [
                {
                  structuredValue: [
                    {
                      value: '1932',
                      type: 'start'
                    },
                    {
                      value: '1935',
                      type: 'end'
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
                  value: '[Tokyo] :'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Dainihon Teikoku Rikuchi Sokuryōbu,'
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
              date: [
                {
                  value: 'Shōwa 7-10 [1932-1935]',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when script tag without altRepGroup and no other originInfo' do
    # based on dt758gj8752, rt337mc1252 (which also have marc junk values - abbreviations! for Latin! for "unknown"!)

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo script="Latn">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">[China</placeTerm>
            </place>
            <publisher>s.n.]</publisher>
          </originInfo>
        XML
      end

      # NOTE: valueLanguage for parallel script/lang - can be at originInfo or publisher
      let(:cocina) do
        {
          event: [
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
                  code: 'cc',
                  source: {
                    code: 'marccountry'
                  }
                },
                {
                  value: '[China'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 's.n.]'
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

  context 'when empty placeTerm and empty date qualifier attribute' do
    # based on gh074sd3455, zp908qm7502
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text"/>
            </place>
            <publisher></publisher>
            <dateIssued encoding="w3cdtf" keyDate="yes" qualifier="">1931</dateIssued>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <dateIssued encoding="w3cdtf" keyDate="yes">1931</dateIssued>
          </originInfo>
        XML
      end

      # should not have empty qualifier on date or location of nil or []
      let(:cocina) do
        {
          event: [
            {
              date: [
                {
                  value: '1931',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  status: 'primary',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when empty placeTerm, dateOther with trailing period and legacy mods displayLabel' do
    # based on wm519yn6490, wm014gp0501
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="producer">
            <place>
              <placeTerm/>
            </place>
            <publisher/>
            <dateOther type="production">June 7, 1977.</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType='production'>
            <dateOther type="production">June 7, 1977</dateOther>
          </originInfo>
        XML
      end

      # should not have empty qualifier on date or location of nil or []
      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              date: [
                {
                  value: 'June 7, 1977',
                  type: 'production'
                }
              ]
            }
          ]
        }
      end
    end
  end
end
