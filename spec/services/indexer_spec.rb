# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexer do
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:druid) { 'druid:bc123df4567' }

  let(:indexer) { double(to_solr: solr_doc) }
  let(:solr_doc) { instance_double(Hash) }
  let(:solr) { instance_double(RSolr::Client, add: nil, commit: nil, delete_by_id: nil) }
  let(:trace_id) { 'abc123' }
  let(:generated_trace_id) { 'def456' }
  let(:current_as_of) { Time.zone.parse('2026-04-10T12:00:00Z') }

  before do
    allow(RSolr).to receive(:connect).and_return(solr)
    allow(SecureRandom).to receive(:uuid).and_return(generated_trace_id)
    allow(Time.zone).to receive(:now).and_return(current_as_of)
  end

  describe '#reindex' do
    before do
      allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    end

    it 'reindexes the object' do
      described_class.reindex(cocina_object:, trace_id:)
      expect(Indexing::Builders::DocumentBuilder).to have_received(:for).with(
        model: cocina_object,
        trace_id:,
        current_as_of: nil
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
          trace_id: generated_trace_id,
          current_as_of: nil
        )
      end
    end
  end

  describe '#reindex_by_druid' do
    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(described_class).to receive(:reindex)
    end

    it 'finds by druid and reindexes the object' do
      described_class.reindex_by_druid(druid:, trace_id:)

      expect(CocinaObjectStore).to have_received(:find).with(druid, validate: false)
      expect(described_class).to have_received(:reindex).with(cocina_object:, trace_id:, current_as_of: nil)
    end

    it 'passes current_as_of to reindex' do
      described_class.reindex_by_druid(druid:, trace_id:, current_as_of:)

      expect(described_class).to have_received(:reindex).with(cocina_object:, trace_id:, current_as_of:)
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
        trace_id:,
        current_as_of:
      )
    end

    context 'when trace_id is not provided' do
      it 'generates a trace_id' do
        described_class.reindex_later(druid:)
        expect(ReindexJob).to have_received(:perform_later).with(
          druid:,
          trace_id: generated_trace_id,
          current_as_of:
        )
      end
    end
  end
end
