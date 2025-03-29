# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexer do
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:druid) { 'druid:bc123df4567' }

  let(:indexer) { double(to_solr: solr_doc) } # rubocop:disable RSpec/VerifiedDoubles
  let(:solr_doc) { instance_double(Hash) }
  let(:solr) { instance_double(RSolr::Client, add: nil, commit: nil, delete_by_id: nil) }
  let(:trace_id) { 'abc123' }
  let(:generated_trace_id) { 'def456' }

  before do
    allow(RSolr).to receive(:connect).and_return(solr)
    allow(SecureRandom).to receive(:uuid).and_return(generated_trace_id)
  end

  describe '#reindex' do
    before do
      allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    end

    it 'reindexes the object' do
      described_class.reindex(cocina_object:, trace_id:)
      expect(Indexing::Builders::DocumentBuilder).to have_received(:for).with(
        model: cocina_object,
        trace_id:
      )
      expect(solr).to have_received(:add).with(solr_doc)
      expect(solr).to have_received(:commit)
    end

    context 'when solr is not enabled' do
      before do
        allow(Settings.solr).to receive(:enabled).and_return(false)
      end

      it 'does not reindex the object' do
        described_class.reindex(cocina_object:, trace_id:)
        expect(Indexing::Builders::DocumentBuilder).not_to have_received(:for)
        expect(solr).not_to have_received(:add)
        expect(solr).not_to have_received(:commit)
      end
    end

    context 'when trace_id is not provided' do
      it 'generates a trace_id' do
        described_class.reindex(cocina_object:)
        expect(Indexing::Builders::DocumentBuilder).to have_received(:for).with(
          model: cocina_object,
          trace_id: generated_trace_id
        )
      end
    end
  end

  describe '#delete' do
    it 'reindexes the object' do
      described_class.delete(druid:)
      expect(solr).to have_received(:delete_by_id).with(druid)
      expect(solr).to have_received(:commit)
    end

    context 'when solr is not enabled' do
      before do
        allow(Settings.solr).to receive(:enabled).and_return(false)
      end

      it 'does not delete the object' do
        described_class.delete(druid:)
        expect(solr).not_to have_received(:delete_by_id)
        expect(solr).not_to have_received(:commit)
      end
    end
  end

  describe '#reindex_later' do
    before do
      allow(ReindexJob).to receive(:perform_later)
    end

    it 'reindexes the object later' do
      described_class.reindex_later(druid:, trace_id:)
      expect(ReindexJob).to have_received(:perform_later).with(
        druid:,
        trace_id:
      )
    end

    context 'when trace_id is not provided' do
      it 'generates a trace_id' do
        described_class.reindex_later(druid:)
        expect(ReindexJob).to have_received(:perform_later).with(
          druid:,
          trace_id: generated_trace_id
        )
      end
    end
  end
end
