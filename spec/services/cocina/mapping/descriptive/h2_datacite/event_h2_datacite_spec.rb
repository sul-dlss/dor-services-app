# frozen_string_literal: true

require 'rails_helper'

# For DataCite publication year, use year embargo lifted if present, otherwise use deposit year, regardless of publication date entered
# H2 publication date > cocina event/date type publication > DataCite date type Issued
# H2 deposit date > cocina event type deposit > DataCite date type Submitted
## If no embargo, > cocina date type publication
## If embargo, > cocina date type deposit
# H2 embargo end date > cocina event type release and date type publication > DataCite date type Available
# H2 creation date > cocina event/date type creation > DataCite date type Creation
# H2 publisher role > same cocina event as publication date > see DataCite contributor mappings
# Add Stanford Digital Repository as publisher to cocina release event if present, otherwise deposit event

RSpec.describe 'Cocina --> DataCite mappings for event (h2 specific)' do
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Issued">2021-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Issued">2020-01-01</date>
            <date dateType="Available">2022-01-01</date>
            <date dateType="Submitted">2021-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Available">2022-01-01</date>
            <date dateType="Submitted">2021-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2021</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Submitted">2021-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Created">2021-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Created">2020-01-01/2021-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <publicationYear>2023</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation">2021-01-01</date>
            <date dateType="Available">2023-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <contributors>
            <contributor contributorType="Distributor">
              <contributorName nameType="Organizational">Stanford University Press</contributorName>
            </contributor>
          </contributors>
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Creation">2021-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
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

      let(:datacite) do
        <<~XML
          <contributors>
            <contributor contributorType="Distributor">
              <contributorName nameType="Organizational">Stanford University Press</contributorName>
            </contributor>
          </contributors>
          <publicationYear>2022</publicationYear>
          <publisher>Stanford Digital Repository</publisher>
          <dates>
            <date dateType="Issued">2021-01-01</date>
            <date dateType="Submitted">2022-01-01</date>
          </dates>
        XML
      end
    end
  end
end
