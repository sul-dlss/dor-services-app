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

  describe 'subject mappings from Cocina to Solr sw_subject_temporal_ssimdv' do
    context 'when single temporal subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: '14th century',
              type: 'time'
            }
          ]
        }
      end

      it 'selects temporal subject' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century'])
      end
    end

    context 'when multiple temporal subjects' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: '14th century',
              type: 'time'
            },
            {
              value: '15th century',
              type: 'time'
            }
          ]
        }
      end

      it 'selects temporal subjects' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century'])
      end
    end

    context 'when temporal subject is range' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              structuredValue: [
                {
                  value: '14th century',
                  type: 'start'
                },
                {
                  value: '15th century',
                  type: 'end'
                }
              ],
              type: 'time'
            }
          ]
        }
      end

      it 'selects both temporal subjects in range' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century'])
      end
    end

    context 'when temporal subject has encoding' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: '1400',
              type: 'time',
              encoding: {
                code: 'w3cdtf'
              }
            }
          ]
        }
      end

      it 'selects temporal subject' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['1400'])
      end
    end

    context 'when temporal subject is part of complex subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              structuredValue: [
                {
                  value: 'Europe',
                  type: 'place'
                },
                {
                  value: '14th century',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end

      it 'selects temporal subject from complex subject' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century'])
      end
    end

    context 'when temporal subject range is part of complex subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Europe',
              type: 'place'
            },
            {
              structuredValue: [
                {
                  value: '14th century',
                  type: 'start'
                },
                {
                  value: '15th century',
                  type: 'end'
                }
              ],
              type: 'time'
            }
          ]
        }
      end

      it 'selects temporal subject range from complex subject' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century'])
      end
    end

    context 'when temporal subject in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  value: '14th century',
                  type: 'time'
                },
                {
                  value: 'XIVieme siecle',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end

      it 'selects temporal subjects from parallelValue' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', 'XIVieme siecle'])
      end
    end

    context 'when temporal subject range in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: '14th century',
                      type: 'start'
                    },
                    {
                      value: '15th century',
                      type: 'end'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'XIVieme siecle',
                      type: 'start'
                    },
                    {
                      value: 'XVieme siecle',
                      type: 'end'
                    }
                  ]
                }
              ],
              type: 'time'
            }
          ]
        }
      end

      it 'selects temporal subject range from parallelValue' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century', 'XIVieme siecle',
                                                                'XVieme siecle'])
      end
    end

    context 'when complex subject in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: '14th century',
                      type: 'time'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: 'XIVieme siecle',
                      type: 'time'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects temporal subjects from complex subjects' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', 'XIVieme siecle'])
      end
    end

    context 'when range in complex subject in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: '14th century',
                      type: 'time'
                    },
                    {
                      value: '15th century',
                      type: 'time'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: 'XIVieme siecle',
                      type: 'time'
                    },
                    {
                      value: 'XVieme siecle',
                      type: 'time'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects temporal range from complex subjects' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century', 'XIVieme siecle',
                                                                'XVieme siecle'])
      end
    end

    context 'when temporal subject is duplicated across multiple complex subjects' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              structuredValue: [
                {
                  value: 'Europe',
                  type: 'place'
                },
                {
                  value: '14th century',
                  type: 'time'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Africa',
                  type: 'place'
                },
                {
                  value: '14th century',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end

      it 'drops duplicate value' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '14th century'])
      end
    end

    context 'when temporal subject has trailing punctuation to drop' do
      # punctuation dropped at end of value: backslash, comma, semicolon, along with space
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: '14th century,',
              type: 'time'
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century'])
      end
    end

    context 'when temporal subject range has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              structuredValue: [
                {
                  value: '14th century;',
                  type: 'start'
                },
                {
                  value: '15th century;',
                  type: 'end'
                }
              ],
              type: 'time'
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century'])
      end
    end

    context 'when complex subject has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              structuredValue: [
                {
                  value: 'Europe',
                  type: 'place'
                },
                {
                  value: '14th century \\',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century'])
      end
    end

    context 'when range in complex subject has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Europe',
              type: 'place'
            },
            {
              structuredValue: [
                {
                  value: '14th century\\',
                  type: 'start'
                },
                {
                  value: '15th century\\',
                  type: 'end'
                }
              ],
              type: 'time'
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century'])
      end
    end

    context 'when temporal subject in parallelValue has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  value: '14th century,',
                  type: 'time'
                },
                {
                  value: 'XIVieme siecle,',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', 'XIVieme siecle'])
      end
    end

    context 'when complex subject in parallelValue has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: '14th century ;',
                      type: 'time'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: 'XIVieme siecle ;',
                      type: 'time'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', 'XIVieme siecle'])
      end
    end

    context 'when range in complex subject in parallelValue has trailing punctuation to drop' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: '14th century;',
                      type: 'time'
                    },
                    {
                      value: '15th century;',
                      type: 'time'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Europe',
                      type: 'place'
                    },
                    {
                      value: 'XIVieme siecle;',
                      type: 'time'
                    },
                    {
                      value: 'XVieme siecle;',
                      type: 'time'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'drops punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century', '15th century', 'XIVieme siecle',
                                                                'XVieme siecle'])
      end
    end

    context 'when temporal subject has trailing punctuation not dropped' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: '14th century.',
              type: 'time'
            }
          ]
        }
      end

      it 'does not drop punctuation' do
        expect(doc).to include('sw_subject_temporal_ssimdv' => ['14th century.'])
      end
    end
  end
end
