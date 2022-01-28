# frozen_string_literal: true

require 'rails_helper'

# Unit tests for Cocina::ToDatacite::Event.pub_year (which will become DataCite publicationYear)
RSpec.describe Cocina::ToDatacite::Event do
  let(:cocina_description) do
    cocina[:title] = [{ value: 'title' }]
    cocina[:purl] = 'https://purl.stanford.edu/zg154pd4168'
    Cocina::Models::Description.new(cocina)
  end
  let(:cocina_item) do
    Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                            label: 'This is my label',
                            version: 1,
                            administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                            description: cocina_description,
                            identification: { sourceId: 'cats:dogs' },
                            externalIdentifier: 'druid:cc123dd1234',
                            structural: {},
                            access: cocina_access)
  end
  let(:mapped_event_instance) { described_class.new(cocina_item) }
  let(:pub_year) { mapped_event_instance.pub_year }

  describe '#pub_year' do
    # DataCite publicationYear is the year (YYYY) the object is published to purl, and is either:
    ## The embargo end date, if present (cocina event type release, date type publication)
    ## The deposit date (cocina event type deposit, date type publication)

    describe 'Publication date: 2021-01-01, Embargo: none, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq '2022'
      end
    end

    describe 'Publication date entered as: 2020-01-01, Embargo: until 2022-01-01, Deposited: 2021-01-01' do
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
      let(:cocina_access) do
        {
          embargo:
            {
              access: 'world',
              download: 'world',
              releaseDate: DateTime.parse('2022-01-01'),
              useAndReproductionStatement: 'in public domain'
            }
        }
      end

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'No publication date provided, Embargo: until 2022-01-01, Deposited: 2021-01-01' do
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
      let(:cocina_access) do
        {
          embargo:
            {
              access: 'world',
              download: 'world',
              releaseDate: DateTime.parse('2022-01-01'),
              useAndReproductionStatement: 'in public domain'
            }
        }
      end

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'No publication date provided, Embargo: none, Deposited: 2021-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2021')
      end
    end

    describe 'Creation date: 2021-01-01, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Creation date range: 2020-01-01 to 2021-01-01, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Approximate single creation date, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Approximate creation start date: approx. 1900, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Approximate creation end date: approx. 1900, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Approximate creation date range: approx. 1900, Deposited: 2022-01-01' do
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Creation date: 2021-01-01, Embargo: until 2023-01-01, Deposited: 2022-01-01' do
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
      let(:cocina_access) do
        {
          embargo:
            {
              access: 'world',
              download: 'world',
              releaseDate: DateTime.parse('2023-01-01'),
              useAndReproductionStatement: 'in public domain'
            }
        }
      end

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2023')
      end
    end

    describe 'Creation date: 2021-01-01, Deposited: 2022-01-01, Uncited publisher: Stanford University Press' do
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
                      },
                      note: [
                        {
                          type: 'citation status',
                          value: 'false'
                        }
                      ]
                    },
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
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    describe 'Publication date: 2021-01-01, Deposited: 2022-01-01, Uncited publisher: Stanford University Press' do
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
                      note: [
                        {
                          type: 'citation status',
                          value: 'false'
                        }
                      ]
                    },
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
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
      let(:cocina_access) { {} } # no embargo

      it 'populates pub_year correctly' do
        expect(pub_year).to eq('2022')
      end
    end

    ### --------------- specs below added by developers ---------------

    context 'when cocina event array has empty hash' do
      let(:cocina) do
        {
          event: [
            {
            }
          ]
        }
      end
      let(:cocina_access) { {} }

      it 'pub_year is nil' do
        expect(pub_year).to eq nil
      end
    end

    context 'when cocina event is empty array' do
      let(:cocina) do
        {
          event: []
        }
      end
      let(:cocina_access) { {} }

      it 'pub_year is nil' do
        expect(pub_year).to eq nil
      end
    end

    context 'when cocina has no event attribute' do
      let(:cocina) do
        {
        }
      end
      let(:cocina_access) { {} }

      it 'pub_year is nil' do
        expect(pub_year).to eq nil
      end
    end
  end
end
