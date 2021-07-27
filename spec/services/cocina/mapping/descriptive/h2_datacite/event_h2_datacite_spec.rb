# frozen_string_literal: true

require 'rails_helper'

# DataCite publicationYear is the year (YYYY) the object is published to purl, and is either:
## The embargo end date, if present (cocina event type release, date type publication)
## The deposit date (cocina event type deposit, date type publication)
#
# DataCite date (YYYY-MM-DD) is repeatable and has an associated type attribute:
# Cocina event type publication, date type publication maps to DataCite date type Issued
# Cocina event type deposit, date type deposit maps to DataCite date type Submitted
# Cocina event type deposit, date type publication maps to DataCite date type Submitted
# Cocina event type release, date type publication maps to DataCite date type Available
# Cocina event type creation, date type creation maps to DataCite date type Created
#
# DataCite publisher is always Stanford Digital Repository

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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Issued">2021-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Issued'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Issued">2020-01-01</date>
      #       <date dateType="Available">2022-01-01</date>
      #       <date dateType="Submitted">2021-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2020-01-01',
                  dateType: 'Issued'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Available'
                },
                {
                  date: '2021-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Available">2022-01-01</date>
      #       <date dateType="Submitted">2021-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2022-01-01',
                  dateType: 'Available'
                },
                {
                  date: '2021-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2021</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Submitted">2021-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2021',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Created">2021-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Created'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Created">2020-01-01/2021-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2020-01-01/2021-01-01',
                  dateType: 'Created'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Approximate single creation date: 1900, Deposited: 2022-01-01' do
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation" dateInformation="Approximate">1900</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '1900',
                  dateType: 'Created',
                  dateInformation: 'approximate'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Approximate creation start date: approx. 1900-1910, Deposited: 2022-01-01' do
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '1900/1910',
                  dateType: 'Created',
                  dateInformation: 'approximate'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Approximate creation end date: 1900-approx. 1910, Deposited: 2022-01-01' do
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '1900/1910',
                  dateType: 'Created',
                  dateInformation: 'approximate'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Approximate creation date range: approx. 1900-approx. 1910, Deposited: 2022-01-01' do
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '1900/1910',
                  dateType: 'Created',
                  dateInformation: 'approximate'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <publicationYear>2023</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation">2021-01-01</date>
      #       <date dateType="Available">2023-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2023',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Created'
                },
                {
                  date: '2023-01-01',
                  dateType: 'Available'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <contributors>
      #       <contributor contributorType="Distributor">
      #         <contributorName nameType="Organizational">Stanford University Press</contributorName>
      #       </contributor>
      #     </contributors>
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Creation">2021-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              contributors: [
                {
                  name: 'Stanford University Press',
                  nameType: 'Organizational',
                  contributorType: 'Distributor'
                }
              ],
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Created'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
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

      # let(:datacite_xml) do
      #   <<~XML
      #     <contributors>
      #       <contributor contributorType="Distributor">
      #         <contributorName nameType="Organizational">Stanford University Press</contributorName>
      #       </contributor>
      #     </contributors>
      #     <publicationYear>2022</publicationYear>
      #     <publisher>Stanford Digital Repository</publisher>
      #     <dates>
      #       <date dateType="Issued">2021-01-01</date>
      #       <date dateType="Submitted">2022-01-01</date>
      #     </dates>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              contributors: [
                {
                  name: 'Stanford University Press',
                  nameType: 'Organizational',
                  contributorType: 'Distributor'
                }
              ],
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository',
              dates: [
                {
                  date: '2021-01-01',
                  dateType: 'Issued'
                },
                {
                  date: '2022-01-01',
                  dateType: 'Submitted'
                }
              ]
            }
          }
        }
      end
    end
  end
end
