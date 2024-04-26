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

  describe 'place mappings from Cocina to Solr originInfo_place_placeTerm_tesim' do
    # Constructs single place value from a selected event
    # marccountry code mapping: https://github.com/sul-dlss/stanford-mods/blob/master/lib/marc_countries.rb
    context 'when single place text value' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'Stanford (Calif.)'
                }
              ]
            }
          ]
        }
      end

      it 'selects one place text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Stanford (Calif.)')
      end
    end

    context 'when multiple place text values, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'Stanford (Calif.)'
                },
                {
                  value: 'United States'
                }
              ]
            }
          ]
        }
      end

      it 'selects all place text values and concatenates with space colon space' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Stanford (Calif.) : United States')
      end
    end

    context 'when multiple place text values, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'Stanford (Calif.)',
                  status: 'primary'
                },
                {
                  value: 'United States'
                }
              ]
            }
          ]
        }
      end

      it 'selects primary place text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Stanford (Calif.)')
      end
    end

    context 'when place code with marccountry authority' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  code: 'cau',
                  source: {
                    code: 'marccountry'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'selects marccountry place code and maps to text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'California')
      end
    end

    context 'when place code with marccountry authorityURI' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  code: 'cau',
                  source: {
                    uri: 'http://id.loc.gov/vocabulary/countries/'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'selects marccountry place code and maps to text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'California')
      end
    end

    context 'when place code with marccountry valueURI' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  uri: 'http://id.loc.gov/vocabulary/countries/cau'
                }
              ]
            }
          ]
        }
      end

      it 'selects marccountry place code and maps to text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'California')
      end
    end

    context 'when place code with non-marccountry authority' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  code: 'n-us-ca',
                  source: {
                    code: 'marcgac'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'does not select a place' do
        expect(doc).not_to include('originInfo_place_placeTerm_tesim')
      end
    end

    context 'when text and marccountry code in same location' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'California',
                  code: 'cau',
                  source: {
                    code: 'marccountry'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'selects the place text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'California')
      end
    end

    context 'when text and marccountry code in different locations' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'Stanford (Calif.)'
                },
                {
                  code: 'cau',
                  source: {
                    code: 'marccountry'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'selects the place text value and omits the code' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Stanford (Calif.)')
      end
    end

    context 'when place text and non-marccountry code' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  value: 'California',
                  code: 'n-us-ca',
                  source: {
                    code: 'marcgac'
                  }
                }
              ]
            }
          ]
        }
      end

      it 'selects the place text value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'California')
      end
    end

    context 'when parallelEvent, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  location: [
                    {
                      value: 'Moscow'
                    }
                  ]
                },
                {
                  location: [
                    {
                      value: 'Москва'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects all values and concatenates with space colon space' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Moscow : Москва')
      end
    end

    context 'when parallelEvent, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              parallelEvent: [
                {
                  location: [
                    {
                      value: 'Moscow'
                    }
                  ]
                },
                {
                  location: [
                    {
                      value: 'Москва',
                      status: 'primary'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects primary value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Москва')
      end
    end

    context 'when parallelValue, none primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Moscow'
                    },
                    {
                      value: 'Москва'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects all values and concatenates with space colon space' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Moscow : Москва')
      end
    end

    context 'when parallelValue, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  parallelValue: [
                    {
                      value: 'Moscow',
                      status: 'primary'
                    },
                    {
                      value: 'Москва'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'selects primary value' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Moscow')
      end
    end

    context 'when structuredValue' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              location: [
                {
                  structuredValue: [
                    {
                      value: 'Stanford'
                    },
                    {
                      value: 'California'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it 'concatenates structured value with space colon space' do
        expect(doc).to include('originInfo_place_placeTerm_tesim' => 'Stanford : California')
      end
    end
  end
end
