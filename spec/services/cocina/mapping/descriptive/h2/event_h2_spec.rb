# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for event (h2 specific)' do
  describe 'Publication date: 2021-01-01, Embargo: none, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                value: '2022-01-01',
                type: 'publication',
                encoding: {
                  code: 'w3cdtf'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">2021-01-01</dateIssued>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publication date entered as: 2020-01-01, Embargo: until 2022-01-01, Deposited: 2021-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2020-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'release',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2021-01-01',
                  type: 'deposit',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">2020-01-01</dateIssued>
          </originInfo>
          <originInfo eventType="release">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
          <originInfo eventType="deposit">
            <dateOther type="deposit" encoding="w3cdtf">2021-01-01</dateOther>
          </originInfo>
        XML
      end
    end
  end

  describe 'No publication date provided, Embargo: until 2022-01-01, Deposited: 2021-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'release',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2021-01-01',
                  type: 'deposit',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="release">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
          <originInfo eventType="deposit">
            <dateOther type="deposit" encoding="w3cdtf">2021-01-01</dateOther>
          </originInfo>
        XML
      end
    end
  end

  describe 'No publication date provided, Embargo: none, Deposited: 2021-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'deposit',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2021-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf">2021-01-01</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date range: 2020-01-01 to 2021-01-01, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '2020-01-01',
                      type: 'start'
                    },
                    {
                      value: '2021-01-01',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf" point="start">2020-01-01</dateCreated>
            <dateCreated encoding="w3cdtf" point="end">2021-01-01</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate single creation date, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '1900',
                  type: 'creation',
                  qualifier: 'approximate',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf" qualifier="approximate">1900</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate creation start date: approx. 1900, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start',
                      qualifier: 'approximate'
                    },
                    {
                      value: '1910',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf" point="start" qualifier="approximate">1900</dateCreated>
            <dateCreated encoding="w3cdtf" point="end">1910</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate creation end date: approx. 1900, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start'
                    },
                    {
                      value: '1910',
                      type: 'end',
                      qualifier: 'approximate'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf" point="start">1900</dateCreated>
            <dateCreated encoding="w3cdtf" point="end" qualifier="approximate">1910</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate creation date range: approx. 1900, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start'
                    },
                    {
                      value: '1910',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  qualifier: 'approximate',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf" point="start" qualifier="approximate">1900</dateCreated>
            <dateCreated encoding="w3cdtf" point="end" qualifier="approximate">1910</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, Embargo: until 2023-01-01, Deposited: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'release',
              date: [
                {
                  value: '2023-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'deposit',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf">2021-01-01</dateCreated>
          </originInfo>
          <originInfo eventType="release">
            <dateIssued encoding="w3cdtf">2023-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
          <originInfo eventType="deposit">
            <dateOther type="deposit" encoding="w3cdtf">2022-01-01</dateOther>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, Deposited: 2022-01-01, Uncited publisher: Stanford University Press' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            },
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'Publisher',
                      source: {
                        value: 'H2 contributor role terms'
                      }
                    },
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    },
                    {
                      value: 'Distributor',
                      type: 'DataCite role',
                      source: {
                        value: 'DataCite contributor types'
                      }
                    }
                  ],
                  note: [
                    {
                      type: 'citation status',
                      value: 'false'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="w3cdtf">2021-01-01</dateCreated>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, Deposited: 2022-01-01, Uncited publisher: Stanford University Press' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'Publisher',
                      source: {
                        value: 'H2 contributor role terms'
                      },
                    },
                    {
                      value: 'publisher',
                      code: 'pbl',
                      uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    },
                    {
                      value: 'Distributor',
                      type: 'DataCite role',
                      source: {
                        value: 'DataCite contributor types'
                      }
                    }
                  ],
                  note: [
                    {
                      type: 'citation status',
                      value: 'false'
                    }
                  ],
                  type: 'organization'
                }
              ]
            },
            {
              type: 'deposit',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford Digital Repository'
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
                    },
                    {
                      value: 'Publisher',
                      type: 'DataCite role'
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">2021-01-01</dateIssued>
            <publisher>Stanford University Press</publisher>
          </originInfo>
          <originInfo eventType="deposit">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
            <publisher>Stanford Digital Repository</publisher>
          </originInfo>
        XML
      end
    end
  end
end
