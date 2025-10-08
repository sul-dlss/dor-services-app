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

  describe 'subject mappings from Cocina to Solr topic_ssimdv (facet) and topic_tesim (search)' do
    # topic_tesim: subject/topic
    # topic_ssimdv: subject/topic, subject/name, subject/title, subject/occupation
    context 'when single simple subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Cats',
              type: 'topic'
            }
          ]
        }
      end

      it 'selects topic from subject' do
        expect(doc).to include('topic_ssimdv' => ['Cats'])
        expect(doc).to include('topic_tesim' => ['Cats'])
      end
    end

    context 'when multiple simple subjects' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Cats',
              type: 'topic'
            },
            {
              value: 'Birds',
              type: 'topic'
            }
          ]
        }
      end

      it 'selects topics from multiple subjects' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Birds])
        expect(doc).to include('topic_tesim' => %w[Cats Birds])
      end
    end

    context 'when simple subject in parallelValue' do
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
                  value: 'Cats'
                },
                {
                  value: 'Chats'
                }
              ],
              type: 'topic'
            }
          ]
        }
      end

      it 'selects topics from subjects in parallelValue' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Chats])
        expect(doc).to include('topic_tesim' => %w[Cats Chats])
      end
    end

    context 'when single complex subject, one topic' do
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
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Memes',
                  type: 'genre'
                }
              ]
            }
          ]
        }
      end

      it 'selects topic part from complex subject' do
        expect(doc).to include('topic_ssimdv' => ['Cats'])
        expect(doc).to include('topic_tesim' => ['Cats'])
      end
    end

    context 'when multiple complex subjects, one topic each' do
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
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Memes',
                  type: 'genre'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Birds',
                  type: 'topic'
                },
                {
                  value: 'Memes',
                  type: 'genre'
                }
              ]
            }
          ]
        }
      end

      it 'selects topic parts from multiple complex subjects' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Birds])
        expect(doc).to include('topic_tesim' => %w[Cats Birds])
      end
    end

    context 'when single complex subject, multiple topics' do
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
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ]
            }
          ]
        }
      end

      it 'selects topic parts from complex subject' do
        expect(doc).to include('topic_ssimdv' => ['Cats', 'Homes and haunts'])
        expect(doc).to include('topic_tesim' => ['Cats', 'Homes and haunts'])
      end
    end

    context 'when multiple complex subjects, multiple topics each (including duplicate)' do
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
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Birds',
                  type: 'topic'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ]
            }
          ]
        }
      end

      it 'selects topic parts from complex subjects and dedupes' do
        expect(doc).to include('topic_ssimdv' => ['Cats', 'Homes and haunts', 'Birds'])
        expect(doc).to include('topic_tesim' => ['Cats', 'Homes and haunts', 'Birds'])
      end
    end

    context 'when complex subject in parallelValue, one topic each' do
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
                      value: 'Cats',
                      type: 'topic'
                    },
                    {
                      value: 'Memes',
                      type: 'genre'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Chats',
                      type: 'topic'
                    },
                    {
                      value: 'Mèmes',
                      type: 'genre'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects topic parts from complex subjects in parallelValue' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Chats])
        expect(doc).to include('topic_tesim' => %w[Cats Chats])
      end
    end

    context 'when complex subject in parallelValue, multiple topics each' do
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
                      value: 'Cats',
                      type: 'topic'
                    },
                    {
                      value: 'Homes and haunts',
                      type: 'topic'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Chats',
                      type: 'topic'
                    },
                    {
                      value: 'Maisons et repaires',
                      type: 'topic'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects topic parts from complex subjects in parallelValue' do
        expect(doc).to include('topic_ssimdv' => ['Cats', 'Homes and haunts', 'Chats', 'Maisons et repaires'])
        expect(doc).to include('topic_tesim' => ['Cats', 'Homes and haunts', 'Chats', 'Maisons et repaires'])
      end
    end

    context 'when simple name subject' do
      # name subject types: person, organization, family, conference, name
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Sayers, Dorothy L.',
              type: 'person'
            }
          ]
        }
      end

      it 'selects name from subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Sayers, Dorothy L.'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when name subject with display' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            parallelValue: [
              {
                value: 'Sayers, Dorothy L.'
              },
              {
                value: 'Sayers, Dorothy L., 1983-1957',
                type: 'display'
              }
            ],
            type: 'person'
          ]
        }
      end

      it 'selects name from subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Sayers, Dorothy L.'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart name subject' do
      # concatenate in given order with comma space separator EXCEPT:
      # 1. concatenate consecutive surnames with space
      # 2. concatenate consecutive forenames with space
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
                  value: 'Sayers',
                  type: 'surname'
                },
                {
                  value: 'Dorothy',
                  type: 'forename'
                },
                {
                  value: 'L.',
                  type: 'forename'
                }
              ],
              type: 'person'
            }
          ]
        }
      end

      it 'constructs name subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Sayers, Dorothy, L.'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when name subject in parallelValue' do
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
                  value: 'SFU'
                },
                {
                  value: 'СФУ'
                }
              ],
              type: 'organization'
            }
          ]
        }
      end

      it 'selects name subjects from parallelValue for topic_ssimdv' do
        expect(doc).to include('topic_ssimdv' => %w[SFU СФУ])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart name subject in parallelValue' do
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
                      value: 'Sayers',
                      type: 'surname'
                    },
                    {
                      value: 'Dorothy',
                      type: 'forename'
                    },
                    {
                      value: 'L.',
                      type: 'forename'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Сэйерс',
                      type: 'surname'
                    },
                    {
                      value: 'Дороти',
                      type: 'forename'
                    },
                    {
                      value: 'Л.',
                      type: 'forename'
                    }
                  ]
                }
              ],
              type: 'person'
            }
          ]
        }
      end

      it 'constructs names from subjects in parallelValue for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Sayers, Dorothy, L.', 'Сэйерс, Дороти, Л.'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart name in complex subject' do
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
                  structuredValue: [
                    {
                      value: 'Sayers',
                      type: 'surname'
                    },
                    {
                      value: 'Dorothy',
                      type: 'forename'
                    },
                    {
                      value: 'L.',
                      type: 'forename'
                    }
                  ],
                  type: 'person'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ]
            }
          ]
        }
      end

      it 'constructs name subject for topic_ssim and selects topic subject' do
        expect(doc['topic_ssimdv']).to contain_exactly('Sayers, Dorothy, L.', 'Homes and haunts')
        expect(doc).to include('topic_tesim' => ['Homes and haunts'])
      end
    end

    context 'when name-title subject' do
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
                  value: 'Sayers, Dorothy L.',
                  type: 'person'
                },
                {
                  value: 'Gaudy night',
                  type: 'title'
                }
              ]
            }
          ]
        }
      end

      it 'selects name and title subjects for topic_ssim' do
        expect(doc['topic_ssimdv']).to contain_exactly('Sayers, Dorothy L.', 'Gaudy night')
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when title subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Gaudy night',
              type: 'title'
            }
          ]
        }
      end

      it 'selects title subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Gaudy night'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart title subject' do
      # concatenate title parts with space
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              type: 'title',
              structuredValue: [
                {
                  value: 'The',
                  type: 'nonsorting characters'
                },
                {
                  value: 'title',
                  type: 'main title'
                },
                {
                  value: 'with a subtitle',
                  type: 'subtitle'
                },
                {
                  value: 'part 1',
                  type: 'part number'
                },
                {
                  value: 'part the first',
                  type: 'part name'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['The title with a subtitle part 1 part the first'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when title subject in parallelValue' do
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
                  value: 'The master and Margarita'
                },
                {
                  value: 'Мастер и Маргарита'
                }
              ],
              type: 'title'
            }
          ]
        }
      end

      it 'selects title subjects from parallelValue for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['The master and Margarita', 'Мастер и Маргарита'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart title subject in parallelValue' do
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
                      value: 'The master and Margarita',
                      type: 'main title'
                    },
                    {
                      value: 'a novel',
                      type: 'subtitle'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Мастер и Маргарита',
                      type: 'main title'
                    },
                    {
                      value: 'роман',
                      type: 'subtitle'
                    }
                  ]
                }
              ],
              type: 'title'
            }
          ]
        }
      end

      it 'constructs title subjects from parallelValue for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['The master and Margarita a novel', 'Мастер и Маргарита роман'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when multipart title in complex subject' do
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
                  structuredValue: [
                    {
                      value: 'The master and Margarita',
                      type: 'main title'
                    },
                    {
                      value: 'a novel',
                      type: 'subtitle'
                    }
                  ],
                  type: 'title'
                },
                {
                  value: 'Bibliographies',
                  type: 'genre'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['The master and Margarita a novel'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when occupation subject' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Calligraphers',
              type: 'occupation'
            }
          ]
        }
      end

      it 'selects occupation subject for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => ['Calligraphers'])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when occupation subject in parallelValue' do
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
                  value: 'Calligraphers'
                },
                {
                  value: 'Каллиграфы'
                }
              ],
              type: 'occupation'
            }
          ]
        }
      end

      it 'selects occupation subjects from parallelValue for topic_ssim' do
        expect(doc).to include('topic_ssimdv' => %w[Calligraphers Каллиграфы])
        expect(doc).not_to include('topic_tesim')
      end
    end

    context 'when simple subject with trailing punctuation' do
      # comma, semicolon, backslash and trailing spaces stripped for topic_ssimdv
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Cats,',
              type: 'topic'
            }
          ]
        }
      end

      it 'strips trailing punctuation from subject for topic_ssimdv' do
        expect(doc).to include('topic_ssimdv' => ['Cats'])
        expect(doc).to include('topic_tesim' => ['Cats,'])
      end
    end

    context 'when complex subject with trailing punctuation and space' do
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
                  value: 'Cats \\',
                  type: 'topic'
                },
                {
                  value: 'Homes and haunts ;',
                  type: 'topic'
                }
              ]
            }
          ]
        }
      end

      it 'strips trailing punctuation and space from parts of complex subject for topic_ssimdv' do
        expect(doc).to include('topic_ssimdv' => ['Cats', 'Homes and haunts'])
        expect(doc).to include('topic_tesim' => ['Cats \\', 'Homes and haunts ;'])
      end
    end

    context 'when simple subject in parallelValue with trailing punctuation' do
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
                  value: 'Cats,'
                },
                {
                  value: 'Chats,'
                }
              ],
              type: 'topic'
            }
          ]
        }
      end

      it 'strips trailing punctuation from parts of parallelValue for topic_ssimdv' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Chats])
        expect(doc).to include('topic_tesim' => ['Cats,', 'Chats,'])
      end
    end

    context 'when complex subject in parallelValue with trailing punctuation' do
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
                      value: 'Cats;',
                      type: 'topic'
                    },
                    {
                      value: 'Memes',
                      type: 'genre'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Chats \\',
                      type: 'topic'
                    },
                    {
                      value: 'Mèmes',
                      type: 'genre'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'strips trailing punctuation from topic parts of complex subject in parallelValue for topic_ssimdv' do
        expect(doc).to include('topic_ssimdv' => %w[Cats Chats])
        expect(doc).to include('topic_tesim' => ['Cats;', 'Chats \\'])
      end
    end

    context 'when trailing punctuation should be kept for topic_ssimdv' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Cats.',
              type: 'topic'
            }
          ]
        }
      end

      it 'does not strip trailing period' do
        expect(doc).to include('topic_ssimdv' => ['Cats.'])
        expect(doc).to include('topic_tesim' => ['Cats.'])
      end
    end

    context 'when subject is missing a value' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          subject: [
            {
              value: 'Cats.',
              type: 'topic'
            },
            {
              type: 'topic'
            }
          ]
        }
      end

      it 'ignores subjects that are missing a value' do
        expect(doc).to include('topic_tesim' => ['Cats.'])
      end
    end
  end
end
