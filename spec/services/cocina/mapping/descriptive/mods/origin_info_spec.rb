# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings' do
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

  # specs added by devs below

  describe 'parallel values with example adapted from hn285fy7937' do
    # example adapted from hn285fy7937 after normalization

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
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

      let(:warnings) { [Notification.new(msg: 'Bad altRepGroup')] }
    end
  end

  describe 'parallel values - originInfo with additional elements in the second position' do
    # example adapted from bh212vz9239 in different order

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo altRepGroup="1">
            <place>
              <placeTerm type="text">Guangdong in Chinese</placeTerm>
            </place>
            <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
            <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
          </originInfo>
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
        XML
      end

      # all parallel elements in both originInfo elements + eventType
      let(:roundtrip_mods) do
        <<~XML
          <originInfo altRepGroup="1" eventType="publication">
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
          <originInfo altRepGroup="1" eventType="publication">
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
                      value: 'Guangdong in Chinese'
                    },
                    {
                      value: 'Guangdong'
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
                          value: 'Guangdong lu jun ce liang ju in Chinese'
                        },
                        {
                          value: 'Guangdong lu jun ce liang ju'
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
                      value: 'Minguo 11-18 [1922-1929] in Chinese'
                    },
                    {
                      value: 'Minguo 11-18 [1922-1929]'
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

      let(:warnings) { [Notification.new(msg: 'Bad altRepGroup')] }
    end
  end

  describe 'parallel value - with second originInfo that would not get an event type' do
    # from druid:mm706hr7414

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
            <originInfo altRepGroup="1">
              <place>
                <placeTerm type="code" authority="marccountry">is</placeTerm>
              </place>
              <place>
                <placeTerm type="text">Tel-Aviv</placeTerm>
              </place>
              <publisher>A. Shṭibel</publisher>
              <dateIssued>1939</dateIssued>
              <issuance>monographic</issuance>
            </originInfo>
            <originInfo script="" altRepGroup="1">
              <place>
                <placeTerm type="text">תל־אביב :</placeTerm>
              </place>
              <publisher>ש. שטיבל,1939.</publisher>
          </originInfo>
        XML
      end

      # add eventType, all elements must be present in all group members, remove empty script attrib
      let(:roundtrip_mods) do
        <<~XML
            <originInfo altRepGroup="1" eventType="publication">
              <place>
                <placeTerm type="code" authority="marccountry">is</placeTerm>
              </place>
              <place>
                <placeTerm type="text">Tel-Aviv</placeTerm>
              </place>
              <publisher>A. Shṭibel</publisher>
              <dateIssued>1939</dateIssued>
              <issuance>monographic</issuance>
            </originInfo>
            <originInfo altRepGroup="1" eventType="publication">
              <place>
                <placeTerm type="code" authority="marccountry">is</placeTerm>
              </place>
              <place>
                <placeTerm type="text">תל־אביב :</placeTerm>
              </place>
              <publisher>ש. שטיבל,1939.</publisher>
              <dateIssued>1939</dateIssued>
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
                  value: '1939'
                }
              ],
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Tel-Aviv'
                    },
                    {
                      value: 'תל־אביב :'
                    }
                  ]
                },
                {
                  source: {
                    code: 'marccountry'
                  },
                  code: 'is'
                }
              ],
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
                      parallelValue: [
                        {
                          value: 'A. Shṭibel'
                        },
                        {
                          value: 'ש. שטיבל,1939.'
                        }
                      ]
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
              ]
            }
          ]
        }
      end
    end
  end

  context 'when eventType matches date type "distribution"' do
    # NOTE: cocina -> MODS mapping
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="distribution">
            <place>
              <placeTerm type="text">Washington, DC</placeTerm>
            </place>
            <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
            <dateOther/>
          </originInfo>
        XML
      end

      # NOTE: contributor role is distributor, not publisher
      let(:cocina) do
        {
          event: [
            {
              type: 'distribution',
              date: [
                {
                  value: ''
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'For sale by the Superintendent of Documents, U.S. Government Publishing Office'
                    }
                  ],
                  type: 'organization',
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
                  ]
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

  context 'with an originInfo that has place and publisher, but no date (type publication)' do
    # From druid:bs861pk7886

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <publisher>Stanford University. Department of Geophysics</publisher>
          </originInfo>
        XML
      end

      # add eventType and trailing slash on authorityURI
      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <publisher>Stanford University. Department of Geophysics</publisher>
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
                      value: 'Stanford University. Department of Geophysics'
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
                  source: {
                    code: 'marccountry',
                    uri: 'http://id.loc.gov/authorities/names/'
                  },
                  value: 'Stanford (Calif.)'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with multiple events and missing event type' do
    xit 'to be implemented: note that MODS is not correctly mapping to cocina'

    # NOTE: cocina -> MODS mapping
    it_behaves_like 'cocina MODS mapping' do
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

      # FIXME:  3 events - the second date splits to event without type, and location gets type publication
      let(:roundtrip_cocina) do
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
              date: [
                {
                  value: '1901'
                }
              ]
            },
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

      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated>1899</dateCreated>
            <place>
              <placeTerm type="text">York</placeTerm>
            </place>
          </originInfo>
          <originInfo>
            <dateOther>1901</dateOther>
            <place>
              <placeTerm type="text">London</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:warnings) { [Notification.new(msg: 'originInfo/dateOther missing eventType')] }
    end
  end

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

        let(:mods) do
          <<~XML
            <originInfo/>
          XML
        end
      end
    end

    context 'when MODS is empty originInfo element with no attributes' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo/>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
          XML
        end

        let(:cocina) do
          {
          }
        end
      end
    end
  end
end
