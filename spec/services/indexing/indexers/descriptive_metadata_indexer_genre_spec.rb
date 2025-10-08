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

  describe 'genre mappings from Cocina to Solr sw_genre_ssimdv' do
    context 'when single genre' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'photographs',
              type: 'genre'
            }
          ]
        }
      end

      it 'uses genre value' do
        expect(doc).to include('sw_genre_ssimdv' => ['photographs'])
      end
    end

    context 'when multiple genres' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'photographs',
              type: 'genre'
            },
            {
              value: 'ambrotypes',
              type: 'genre'
            }
          ]
        }
      end

      it 'uses both genre values' do
        expect(doc).to include('sw_genre_ssimdv' => %w[photographs ambrotypes])
      end
    end

    context 'when multilingual' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              parallelValue: [
                {
                  value: 'photographs',
                  type: 'genre'
                },
                {
                  value: 'фотографии',
                  type: 'genre'
                }
              ]
            }
          ]
        }
      end

      it 'uses both genre values' do
        expect(doc).to include('sw_genre_ssimdv' => %w[photographs фотографии])
      end
    end

    context 'when genre term is capitalized' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'Photographs',
              type: 'genre',
              displayLabel: 'Image type'
            }
          ]
        }
      end

      it 'retains capitalization in Solr' do
        expect(doc).to include('sw_genre_ssimdv' => ['Photographs'])
      end
    end

    context 'when thesis (case-insensitive)' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'Thesis',
              type: 'genre'
            }
          ]
        }
      end

      it 'retains capitalization in Solr' do
        expect(doc).to include('sw_genre_ssimdv' => ['Thesis', 'Thesis/Dissertation'])
      end
    end

    context 'when conference publication (case-insensitive)' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'Conference Publication',
              type: 'genre'
            }
          ]
        }
      end

      it 'retains capitalization in Solr' do
        expect(doc).to include('sw_genre_ssimdv' => ['Conference Publication', 'Conference proceedings'])
      end
    end

    context 'when government publication (case-insensitive)' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'Government publication',
              type: 'genre'
            }
          ]
        }
      end

      it 'retains capitalization in Solr' do
        expect(doc).to include('sw_genre_ssimdv' => ['Government publication', 'Government document'])
      end
    end

    context 'when technical report (case-insensitive)' do
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              value: 'technical report',
              type: 'genre'
            }
          ]
        }
      end

      it 'retains capitalization in Solr' do
        expect(doc).to include('sw_genre_ssimdv' => ['technical report', 'Technical report'])
      end
    end

    context 'when genre has no value' do
      # from zv340pg2457
      let(:description) do
        {
          title: [
            {
              value: 'title'
            }
          ],
          form: [
            {
              type: 'genre',
              source: {
                code: 'aat',
                uri: 'http://vocab.getty.edu/aat/'
              }
            }
          ]
        }
      end

      it 'doc does not include sw_genre_ssim' do
        expect(doc).not_to include('sw_genre_ssimdv')
      end
    end
  end
end
