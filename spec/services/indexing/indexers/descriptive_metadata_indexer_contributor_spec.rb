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

  describe 'contributor mappings (primary and other) from Cocina to Solr' do
    context 'when single contributor' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L.'
                }
              ]
            }
          ]
        }
      end

      it 'selects name of contributor' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L.'])
      end
    end

    context 'when multiple contributors, one with primary status' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L.'
                }
              ],
              status: 'primary'
            },
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ]
            }
          ]
        }
      end

      it 'selects name of contributor with primary status' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L.', 'Dunnett, Dorothy'])
      end
    end

    context 'when multiple contributors, none with primary status' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L.'
                }
              ]
            },
            {
              name: [
                {
                  value: 'Dunnett, Dorothy'
                }
              ]
            }
          ]
        }
      end

      it 'selects name of first contributor' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L.', 'Dunnett, Dorothy'])
      end
    end

    context 'when selected contributor has display name' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957'
                },
                {
                  value: 'Sayers, Dorothy L.',
                  type: 'display'
                }
              ]
            }
          ]
        }
      end

      it 'selects display name of contributor' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
                                                                'Sayers, Dorothy L.'])
      end
    end

    context 'when selected contributor has multiple names, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L.',
                  status: 'primary'
                },
                {
                  value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957'
                }
              ]
            }
          ]
        }
      end

      it 'selects primary name of contributor' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L.',
                                                                'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957'])
      end
    end

    context 'when selected contributor has multiple names, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Sayers, Dorothy L.'
                },
                {
                  value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957'
                }
              ]
            }
          ]
        }
      end

      it 'selects first name of contributor' do
        expect(doc).to include('author_text_nostem_im' => 'Sayers, Dorothy L.',
                               'author_display_ss' => 'Sayers, Dorothy L.',
                               'contributor_text_nostem_im' => ['Sayers, Dorothy L.',
                                                                'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957'])
      end
    end

    context 'when selected name has parallelValue, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Булгаков, Михаил Афанасьевич'
                    },
                    {
                      value: 'Bulgakov, Mikhail Afanasʹevich',
                      status: 'primary'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects primary name from parallelValue' do
        expect(doc).to include('author_text_nostem_im' => 'Bulgakov, Mikhail Afanasʹevich',
                               'author_display_ss' => 'Bulgakov, Mikhail Afanasʹevich',
                               'contributor_text_nostem_im' => ['Булгаков, Михаил Афанасьевич',
                                                                'Bulgakov, Mikhail Afanasʹevich'])
      end
    end

    context 'when selected name has parallelValue, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Булгаков, Михаил Афанасьевич'
                    },
                    {
                      value: 'Bulgakov, Mikhail Afanasʹevich'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects first name from parallelValue' do
        expect(doc).to include('author_text_nostem_im' => 'Булгаков, Михаил Афанасьевич',
                               'author_display_ss' => 'Булгаков, Михаил Афанасьевич',
                               'contributor_text_nostem_im' => ['Булгаков, Михаил Афанасьевич',
                                                                'Bulgakov, Mikhail Afanasʹevich'])
      end
    end

    context 'when selected name has groupedValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  groupedValue: [
                    {
                      value: 'Strachey, Dorothy',
                      type: 'name'
                    },
                    {
                      value: 'Olivia',
                      type: 'pseudonym'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects value with type name' do
        expect(doc).to include('author_text_nostem_im' => 'Strachey, Dorothy',
                               'author_display_ss' => 'Strachey, Dorothy',
                               'contributor_text_nostem_im' => ['Strachey, Dorothy'])
      end
    end

    context 'when selected name has structuredValue with name parts' do
      # Concatenate all with type surname in order provided, space delimeter
      # Concatenate all with type forename in order provided, space delimiter
      # Concatenate all with type term of address in order provided, comma space delimiter
      # Concatenate combined surname with combined forename, comma space delimiter
      # Append combined term of address, space delimiter
      # Append life or activity dates, comma space delimiter
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Dorothy',
                      type: 'forename'
                    },
                    {
                      value: 'Leigh',
                      type: 'forename'
                    },
                    {
                      value: 'Sayers',
                      type: 'surname'
                    },
                    {
                      value: 'Fleming',
                      type: 'surname'
                    },
                    {
                      value: 'B.A. (Oxon.)',
                      type: 'term of address'
                    },
                    {
                      value: 'M.A. (Oxon.)',
                      type: 'term of address'
                    },
                    {
                      value: '1893-1957',
                      type: 'life dates'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'constructs name of contributor' do
        # No comma between name and term of address because also used for e.g. Elizabeth I
        expected_value = 'Sayers Fleming, Dorothy Leigh B.A. (Oxon.), M.A. (Oxon.), 1893-1957'
        expect(doc).to include('author_text_nostem_im' => expected_value,
                               'author_display_ss' => expected_value,
                               'contributor_text_nostem_im' => [expected_value])
      end
    end

    context 'when selected name has structuredValue with full name' do
      # Concatenate all with type term of address in order provided, comma space delimiter
      # Append combined term of address to name, space delimiter
      # Append life or activity dates, comma space delimiter
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Sayers, Dorothy L.',
                      type: 'name'
                    },
                    {
                      value: 'B.A. (Oxon.)',
                      type: 'term of address'
                    },
                    {
                      value: 'M.A. (Oxon.)',
                      type: 'term of address'
                    },
                    {
                      value: '1893-1957',
                      type: 'life dates'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'constructs name of contributor' do
        # No comma between name and term of address because also used for e.g. Elizabeth I
        expected_value = 'Sayers, Dorothy L. B.A. (Oxon.), M.A. (Oxon.), 1893-1957'
        expect(doc).to include('author_text_nostem_im' => expected_value,
                               'author_display_ss' => expected_value,
                               'contributor_text_nostem_im' => [expected_value])
      end
    end

    context 'when selected name has structuredValue with multiple parts with name type' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          contributor: [
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'United States',
                      type: 'name'
                    },
                    {
                      value: 'Office of Foreign Investment in the United States',
                      type: 'name'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'constructs name of contributor' do
        # Concatenate in order given, period space delimiter
        expected_value = 'United States. Office of Foreign Investment in the United States'
        expect(doc).to include('author_text_nostem_im' => expected_value,
                               'author_display_ss' => expected_value,
                               'contributor_text_nostem_im' => [expected_value])
      end
    end
  end
end
