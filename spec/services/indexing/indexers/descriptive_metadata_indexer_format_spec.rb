# frozen_string_literal: true

require 'rails_helper'

# TODO: Remove this spec.
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

  describe 'form/genre mappings from Cocina to Solr sw_format_ssim' do
    context 'when structuredValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Text file houseplant in H2 collection'
            }
          ],
          form: [
            {
              structuredValue: [
                {
                  value: 'Text',
                  type: 'type'
                }
              ],
              type: 'resource type',
              source: { value: 'Stanford self-deposit resource types' }
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when dataset' do
      # value "dataset" is case-insensitive
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'dataset',
              type: 'genre'
            }
          ]
        }
      end

      it 'assigns format based on genre' do
        expect(doc).to include('sw_format_ssimdv' => ['Dataset'])
      end
    end

    context 'when manuscript' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'manuscript',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Archive/Manuscript'])
      end
    end

    context 'when cartographic' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'cartographic',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Map'])
      end
    end

    context 'when mixed material' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'mixed material',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Archive/Manuscript'])
      end
    end

    context 'when moving image' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'moving image',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Video'])
      end
    end

    context 'when notated music' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'notated music',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Music score'])
      end
    end

    context 'when software, multimedia' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'software, multimedia',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Software/Multimedia'])
      end
    end

    context 'when software, multimedia and cartographic' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'software, multimedia',
              type: 'resource type'
            },
            {
              value: 'cartographic',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on cartographic resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Map'])
      end
    end

    context 'when software, multimedia and dataset' do
      # value "dataset" is case-insensitive
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'software, multimedia',
              type: 'resource type'
            },
            {
              value: 'dataset',
              type: 'genre'
            }
          ]
        }
      end

      it 'assigns format based on dataset genre' do
        expect(doc).to include('sw_format_ssimdv' => ['Dataset'])
      end
    end

    context 'when sound recording-musical' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'sound recording-musical',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Music recording'])
      end
    end

    context 'when sound recording-nonmusical' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'sound recording-nonmusical',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Sound recording'])
      end
    end

    context 'when sound recording' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'sound recording',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Sound recording'])
      end
    end

    context 'when still image' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'still image',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Image'])
      end
    end

    context 'when text and book because monographic issuance' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  value: 'monographic',
                  type: 'issuance'
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when text and book because monographic issuance in parallelEvent' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  note: [
                    {
                      value: 'monographic',
                      type: 'issuance'
                    }
                  ]
                },
                {
                  note: [
                    {
                      value: 'Another event'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when text and book because monographic issuance in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  parallelValue: [
                    {
                      value: 'monographic',
                      type: 'issuance'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when text and not book because manuscript' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            },
            {
              value: 'manuscript',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on manuscript resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Archive/Manuscript'])
      end
    end

    context 'when text and periodical because continuing issuance' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  value: 'continuing',
                  type: 'issuance'
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because serial issuance' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  value: 'serial',
                  type: 'issuance'
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because frequency' do
      # actual value of frequency does not matter, so long as it is present
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  value: 'monthly',
                  type: 'frequency'
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and frequency' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because continuing issuance in parallelEvent' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  note: [
                    {
                      value: 'continuing',
                      type: 'issuance'
                    }
                  ]
                },
                {
                  note: [
                    {
                      value: 'Another event'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because serial issuance in parallelEvent' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  note: [
                    {
                      value: 'serial',
                      type: 'issuance'
                    }
                  ]
                },
                {
                  note: [
                    {
                      value: 'Another event'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because frequency in parallelEvent' do
      # actual value of frequency does not matter, so long as it is present
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  note: [
                    {
                      value: 'monthly',
                      type: 'frequency'
                    }
                  ]
                },
                {
                  note: [
                    {
                      value: 'Another event'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and frequency' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because continuing issuance in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  parallelValue: [
                    {
                      value: 'continuing',
                      type: 'issuance'
                    },
                    {
                      value: 'Another value'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because serial issuance in parallelValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  parallelValue: [
                    {
                      value: 'serial',
                      type: 'issuance'
                    },
                    {
                      value: 'Another value'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and issuance' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and periodical because frequency in parallelValue' do
      # actual value of frequency does not matter, so long as it is present
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ],
          event: [
            {
              note: [
                {
                  parallelValue: [
                    {
                      value: 'monthly',
                      type: 'frequency'
                    },
                    {
                      value: 'Another value'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on resource type and frequency' do
        expect(doc).to include('sw_format_ssimdv' => ['Journal/Periodical'])
      end
    end

    context 'when text and archived website' do
      # value "archived website" is case-insensitive
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            },
            {
              value: 'archived website',
              type: 'genre'
            }
          ]
        }
      end

      it 'assigns format based on resource type and genre' do
        expect(doc).to include('sw_format_ssimdv' => ['Archived website'])
      end
    end

    context 'when text and book because not anything else' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ]
        }
      end

      it 'defaults to Book format' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when text and book because not anything else with other form present' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            },
            {
              value: 'article',
              type: 'genre'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Book'])
      end
    end

    context 'when three dimensional object' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'three dimensional object',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Object'])
      end
    end

    context 'when multiple formats in combination not otherwise mapped' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'cartographic',
              type: 'resource type'
            },
            {
              value: 'still image',
              type: 'resource type'
            },
            {
              value: 'dataset',
              type: 'genre'
            }
          ]
        }
      end

      it 'assigns formats based on all resource types and genres' do
        expect(doc).to include('sw_format_ssimdv' => %w[Map Image Dataset])
      end
    end

    context 'when no mapped resource type or genre value' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'dance notation',
              type: 'resource type'
            }
          ]
        }
      end

      it 'does not assign a format' do
        expect(doc).not_to include('sw_format_ssimdv')
      end
    end

    context 'when no mapped type' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'cartographic'
            }
          ]
        }
      end

      it 'does not assign a format' do
        expect(doc).not_to include('sw_format_ssimdv')
      end
    end

    context 'when duplicate formats' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'manuscript',
              type: 'resource type'
            },
            {
              value: 'mixed material',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format once' do
        expect(doc).to include('sw_format_ssimdv' => ['Archive/Manuscript'])
      end
    end

    context 'when parallelValue, shared type' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              parallelValue: [
                {
                  value: 'notated music'
                },
                {
                  value: 'music annotata'
                }
              ],
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns format based on mapped resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Music score'])
      end
    end

    context 'when parallelValue, type on value' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              parallelValue: [
                {
                  value: 'notated music',
                  type: 'resource type'
                },
                {
                  value: 'music annotata'
                }
              ]
            }
          ]
        }
      end

      it 'assigns format based on mapped resource type' do
        expect(doc).to include('sw_format_ssimdv' => ['Music score'])
      end
    end

    context 'when groupedValue (which would be from MODS)' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              groupedValue: [
                {
                  value: 'audio recording',
                  type: 'form'
                },
                {
                  value: '1 audiocassette',
                  type: 'extent'
                }
              ]
            },
            {
              value: 'sound recording',
              type: 'resource type'
            },
            {
              groupedValue: [
                {
                  value: 'transcript',
                  type: 'form'
                },
                {
                  value: '5 pages',
                  type: 'extent'
                }
              ]
            },
            {
              value: 'text',
              type: 'resource type'
            }
          ]
        }
      end

      it 'assigns formats based on resource types' do
        expect(doc).to include('sw_format_ssimdv' => ['Sound recording', 'Book'])
      end
    end
  end
end
