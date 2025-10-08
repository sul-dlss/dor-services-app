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
    # Choose single date from selected event
    context 'when date with status primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2020',
                  status: 'primary'
                },
                {
                  value: '2019'
                }
              ]
            }
          ]
        }
      end

      it 'selects date with status primary' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
      end
    end

    context 'when one publication date, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'publication'
                },
                {
                  value: '2019',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end

      it 'selects date with type publication' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
      end
    end

    context 'when multiple publication dates, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'publication'
                },
                {
                  value: '2019',
                  type: 'publication'
                }
              ]
            }
          ]
        }
      end

      it 'selects first date with type publication' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2019') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2019')
      end
    end

    context 'when no publication date, single creation date, no primary' do
      # date type creation or production
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'creation'
                },
                {
                  value: '2019'
                }
              ]
            }
          ]
        }
      end

      it 'selects date with type creation or production' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
      end
    end

    context 'when no publication date, multiple creation dates, no primary' do
      # date type creation or production
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'production'
                },
                {
                  value: '2019',
                  type: 'creation'
                }
              ]
            }
          ]
        }
      end

      it 'selects first date with type creation or production' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2019') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2019')
      end
    end

    context 'when no publication or creation date, single capture date, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'capture'
                },
                {
                  value: '2019'
                }
              ]
            }
          ]
        }
      end

      it 'selects date with type capture' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2020') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2020')
      end
    end

    context 'when no publication or creation date, multiple capture dates, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              date: [
                {
                  value: '2020',
                  type: 'capture'
                },
                {
                  value: '2019',
                  type: 'capture'
                }
              ]
            }
          ]
        }
      end

      it 'selects first date with type capture' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2019') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2019')
      end
    end

    context 'when no publication, creation, or capture date, single copyright date, no primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2020',
                  type: 'copyright'
                },
                {
                  value: '2019'
                }
              ]
            }
          ]
        }
      end

      it 'selects the earliest date' do
        expect(doc).to include('sw_pub_date_facet_ssi' => '2019') # TODO: Remove
        expect(doc).to include('sw_pub_date_facet_ssidv' => '2019')
      end
    end
  end
end
