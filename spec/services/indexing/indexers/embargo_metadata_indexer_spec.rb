# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::EmbargoMetadataIndexer do
  let(:druid) { 'druid:zz666yy9999' }
  let(:release_date) { '2024-06-06' }
  let(:cocina_item) do
    build(:dro, id: druid).new(
      access: {
        view: 'world',
        download: 'none',
        copyright: 'some student',
        useAndReproductionStatement: 'restricted until embargo lifted',
        embargo: {
          releaseDate: release_date,
          view: 'world',
          download: 'world',
          useAndReproductionStatement: 'freedom reigns'
        }
      }
    )
  end

  let(:indexer) do
    described_class.new(cocina: cocina_item)
  end

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    context 'when embargo.releaseDate is in the future' do
      let(:release_date) { '2024-06-06T07:00:00.000+09:00' }

      it 'sets both embargo fields in Solr doc' do
        expect(doc).to eq('embargo_release_dtsim' => ['2024-06-05T22:00:00Z'],
                          'embargo_status_ssim' => ['embargoed'])
      end
      # rubocop:enable Style/StringHashKeys
    end

    context 'when embargo.releaseDate is in the past' do
      let(:release_date) { '2020-06-06T07:00:00.000+09:00' }

      # rubocop:disable Style/StringHashKeys
      it 'Solr doc has embargo fields' do
        expect(doc).to eq('embargo_release_dtsim' => ['2020-06-05T22:00:00Z'],
                          'embargo_status_ssim' => ['embargoed'])
      end
      # rubocop:enable Style/StringHashKeys
    end

    context 'when there is no embargo' do
      let(:cocina_item) { build(:dro, id: druid) }

      it 'Solr doc does not have embargo fields' do
        expect(doc).to eq({})
      end
    end
  end
end
