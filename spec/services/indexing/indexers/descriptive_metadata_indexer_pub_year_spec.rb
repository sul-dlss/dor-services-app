# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge(purl: "https://purl.stanford.edu/#{bare_druid}")
    )
  end

  describe 'publication year mappings from Cocina to Solr sw_pub_date_facet_ssidv' do
    context 'when event has date.type publication and date.status primary' do
      let(:description) do
        {
          title: [
            {
              value: 'pub dates are fun'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '1827',
                  type: 'creation'
                }
              ]
            },
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

      it 'uses value with status primary' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
      end

      context 'when publication date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'pub dates are fun'
              }
            ],
            event: [
              {
                date: [
                  {
                    structuredValue: [
                      {
                        value: '1940',
                        status: 'primary',
                        type: 'start'
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

        it 'uses value with status primary' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallel publication event with status primary pub date'
              }
            ],
            event: [
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '1999-09-09',
                        type: 'publication',
                        status: 'primary'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses parallelEvent date status primary with type publication' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1999') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1999')
        end
      end
    end

    context 'when event.type publication and event has date.type publication but no date.status primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Work & social justice'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2018',
                  type: 'publication'
                }
              ]
            },
            {
              type: 'publication',
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
                  value: '©2020',
                  type: 'copyright statement'
                }
              ]
            }
          ]
        }
      end

      it 'uses value from type publication' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2018') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2018')
      end

      context 'when publication date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'pub dates are fun'
              }
            ],
            event: [
              {
                date: [
                  {
                    value: '1957',
                    type: 'publication'
                  }
                ]
              },
              {
                type: 'publication',
                date: [
                  {
                    structuredValue: [
                      {
                        value: '1940',
                        type: 'start'
                      },
                      {
                        value: '1945',
                        type: 'end'
                      }
                    ],
                    type: 'publication'
                  }
                ]
              },
              {
                type: 'copyright notice',
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

        it 'uses value from first date of structuredValue' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallelEvent with no status primary publication date'
              }
            ],
            event: [
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '2020-01-01',
                        type: 'publication'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              },
              {
                type: 'publication',
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '2021-01-01',
                        type: 'publication'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses first publication date of parallelValue of type publication' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
        end
      end
    end

    context 'when event has date.type publication and no event.type publication' do
      let(:description) do
        {
          title: [
            {
              value: 'publication dates R us'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '1980-1984',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end

      it 'uses first year of 1980-1984' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '1980') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '1980')
      end

      context 'when publication date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'publication dates R us'
              }
            ],
            event: [
              {
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
                ]
              }
            ]
          }
        end

        it 'uses first year of structuredValue' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1980') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1980')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallelEvent joy'
              }
            ],
            event: [
              {
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
                    ]
                  }
                ]
              },
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '1966',
                        type: 'publication'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses first publication date of parallelValue' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1966') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1966')
        end
      end
    end

    context 'when event has date.type creation, no date.type publication, and date.status primary' do
      let(:description) do
        {
          title: [
            {
              value: 'pub dates are fun'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '1827',
                  type: 'validity'
                }
              ]
            },
            {
              date: [
                {
                  value: '1940-01-01',
                  type: 'creation',
                  status: 'primary',
                  encoding: {
                    code: 'w3cdtf'
                  }
                },
                {
                  value: '1942',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end

      it 'uses creation date' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
      end

      context 'when creation date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'pub dates are fun'
              }
            ],
            event: [
              {
                date: [
                  {
                    structuredValue: [
                      {
                        value: '1940',
                        status: 'primary',
                        type: 'start'
                      },
                      {
                        value: '1945',
                        type: 'end'
                      }
                    ],
                    type: 'creation'
                  },
                  {
                    value: '1948',
                    type: 'creation'
                  }
                ]
              }
            ]
          }
        end

        it 'uses creation date with status primary' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallel creation event with status primary pub date'
              }
            ],
            event: [
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '1999-09-09',
                        type: 'creation',
                        status: 'primary'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses value from parallelEvent date status primary with type publication' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1999') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1999')
        end
      end
    end

    context 'when event.type creation and event has date.type creation but no date.status primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Work & social justice'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2018',
                  type: 'creation'
                }
              ]
            },
            {
              type: 'creation',
              date: [
                {
                  value: '2019',
                  type: 'creation'
                }
              ]
            },
            {
              type: 'copyright notice',
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

      it 'uses value with date of type creation from event type of creation' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2018') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2018')
      end

      context 'when creation date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'pub dates are fun'
              }
            ],
            event: [
              {
                date: [
                  {
                    value: '1957',
                    type: 'creation'
                  }
                ]
              },
              {
                type: 'creation',
                date: [
                  {
                    structuredValue: [
                      {
                        value: '1940',
                        type: 'start'
                      },
                      {
                        value: '1945',
                        type: 'end'
                      }
                    ],
                    type: 'creation'
                  }
                ]
              },
              {
                type: 'copyright notice',
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

        it 'uses first date of structuredValue of type creation from event of type creation' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1940') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1940')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallelEvent with no status primary creation date'
              }
            ],
            event: [
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '2020-01-01',
                        type: 'creation'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              },
              {
                type: 'creation',
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '2021-01-01',
                        type: 'creation'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses first publication date of parallelValue of type publication' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
        end
      end
    end

    context 'when event has date.type creation and no event.type creation' do
      let(:description) do
        {
          title: [
            {
              value: 'creation dates R us'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '1980-1984',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end

      it 'uses first year of 1980-1984 from date with type creation' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '1980') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '1980')
      end

      context 'when creation date is range (structuredValue)' do
        let(:description) do
          {
            title: [
              {
                value: 'creation dates R us'
              }
            ],
            event: [
              {
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

        it 'uses first year of structuredValue for date of type creation' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1980') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1980')
        end
      end

      context 'when parallelEvent' do
        # based on sf449my9678
        let(:description) do
          {
            title: [
              {
                value: 'parallelEvent joy'
              }
            ],
            event: [
              {
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
                    ]
                  }
                ]
              },
              {
                parallelEvent: [
                  {
                    date: [
                      {
                        value: '1966',
                        type: 'creation'
                      }
                    ],
                    location: [
                      {
                        value: 'Chengdu'
                      }
                    ]
                  },
                  {
                    location: [
                      {
                        value: '成都：'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end

        it 'uses first publication date of parallelValue' do
          expect(doc).to include('sw_pub_date_facet_ssi' => '1966') # TODO: Remove
          expect(doc).to include('sw_pub_date_facet_ssidv' => '1966')
        end
      end
    end
  end
end
