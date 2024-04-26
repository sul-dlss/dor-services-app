# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexer do
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:druid) { 'druid:bc123df4567' }

  let(:indexer) { double(to_solr: solr_doc) } # rubocop:disable RSpec/VerifiedDoubles
  let(:solr_doc) { instance_double(Hash) }
  let(:solr) { instance_double(RSolr::Client, add: nil, commit: nil, delete_by_id: nil) }

  before do
    allow(RSolr).to receive(:connect).and_return(solr)
  end

  describe '#reindex' do
    before do
      allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    end

    it 'reindexes the object' do
      described_class.reindex(cocina_object:)
      expect(Indexing::Builders::DocumentBuilder).to have_received(:for).with(
        model: cocina_object
      )
      expect(solr).to have_received(:add).with(solr_doc)
      expect(solr).to have_received(:commit)
    end
  end

  describe '#delete' do
    it 'reindexes the object' do
      described_class.delete(druid:)
      expect(solr).to have_received(:delete_by_id).with(druid)
      expect(solr).to have_received(:commit)
    end
  end

  describe '#reindex_later' do
    before do
      allow(ReindexJob).to receive(:perform_later)
    end

    it 'reindexes the object later' do
      described_class.reindex_later(cocina_object:)
      expect(ReindexJob).to have_received(:perform_later).with(
        model: cocina_object.to_h,
        created: cocina_object.created,
        modified: cocina_object.modified
      )
    end
  end
end
