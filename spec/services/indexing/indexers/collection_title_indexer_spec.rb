# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::CollectionTitleIndexer do
  let(:druid) { 'druid:rt923jk3422' }
  let(:apo_id) { 'druid:bd999bd9999' }
  let(:cocina_item) { build(:dro, id: druid) }
  let(:indexer) { described_class.new(cocina: cocina_item, parent_collections: collections, administrative_tags: []) }

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }
    let(:bare_collection_druid) { 'qf999gg9999' }
    let(:collection_druid) { "druid:#{bare_collection_druid}" }

    context 'when no collections are provided' do
      let(:collections) { [] }

      it "doesn't raise an error" do
        expect(doc['collection_title_ssim']).to be_nil # TODO: Remove
        expect(doc['collection_title_ssimdv']).to be_nil
        expect(doc['collection_title_tesim']).to be_nil
      end
    end

    context 'when related collections are provided' do
      let(:collections) { [collection] }
      let(:collection) { build(:collection, id: collection_druid, title: 'Collection test object') }

      it 'generates collection title fields' do
        expect(doc['collection_title_ssim'].first).to eq 'Collection test object' # TODO: Remove
        expect(doc['collection_title_ssimdv'].first).to eq 'Collection test object'
        expect(doc['collection_title_tesim'].first).to eq 'Collection test object'
      end
    end
  end
end
