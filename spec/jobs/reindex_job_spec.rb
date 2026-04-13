# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexJob do
  subject(:perform) do
    described_class.perform_now(druid: dro.externalIdentifier, trace_id:, current_as_of:)
  end

  let(:dro) { build(:dro) }
  let(:trace_id) { 'abc123' }
  let(:current_as_of) { nil }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(dro)
    allow(SolrService).to receive(:query).and_return([])
  end

  context 'when no errors' do
    before do
      allow(Indexer).to receive(:reindex)
      allow(RedisLock).to receive(:with_lock) { |*_args, &block| block.call }
    end

    it 'invokes the Indexer' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: dro, trace_id:, current_as_of:)
      expect(CocinaObjectStore).to have_received(:find).with(dro.externalIdentifier, validate: false)
      expect(SolrService).not_to have_received(:query)
      expect(RedisLock).to have_received(:with_lock).with(key: "reindex-#{dro.externalIdentifier}", lock_timeout: 30)
    end
  end

  context 'when an error' do
    before do
      allow(Indexer).to receive(:reindex).and_raise(CocinaObjectStore::CocinaObjectStoreError)
      allow(Honeybadger).to receive(:notify)
      allow(RedisLock).to receive(:with_lock) { |*_args, &block| block.call }
    end

    it 'Honeybadger alerts' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: dro, trace_id:, current_as_of:)
      expect(Honeybadger).to have_received(:notify).with(instance_of(CocinaObjectStore::CocinaObjectStoreError),
                                                         context: { druid: dro.externalIdentifier, trace_id: })
      expect(RedisLock).to have_received(:with_lock)
    end
  end

  context 'when getting a lock fails' do
    before do
      allow(RedisLock).to receive(:with_lock).and_return(false)
    end

    it 'raises' do
      expect do
        described_class.new.perform(druid: dro.externalIdentifier, trace_id:, current_as_of:)
      end.to raise_error(ReindexJob::DeadLockError)
    end
  end

  context 'when current_as_of is provided' do
    let(:current_as_of) { Time.zone.parse('2026-04-10T12:00:00Z') }

    before do
      allow(Indexer).to receive(:reindex)
      allow(RedisLock).to receive(:with_lock) { |*_args, &block| block.call }
    end

    context 'when Solr has a newer current_as_of timestamp' do
      before do
        allow(SolrService).to receive(:query).and_return([{ 'current_as_of_dttsi' => '2026-04-10T12:00:01.012345Z' }])
      end

      it 'skips reindexing' do
        perform

        expect(SolrService).to have_received(:query).with("id:\"#{dro.externalIdentifier}\"",
                                                          fl: 'current_as_of_dttsi', rows: 1)
        expect(RedisLock).not_to have_received(:with_lock)
        expect(CocinaObjectStore).not_to have_received(:find)
        expect(Indexer).not_to have_received(:reindex)
      end
    end

    context 'when Solr has an older current_as_of timestamp' do
      before do
        allow(SolrService).to receive(:query).and_return([{ 'current_as_of_dttsi' => '2026-04-10T11:59:59.987654Z' }])
      end

      it 'reindexes the object' do
        perform

        expect(SolrService).to have_received(:query).with("id:\"#{dro.externalIdentifier}\"",
                                                          fl: 'current_as_of_dttsi', rows: 1)
        expect(RedisLock).to have_received(:with_lock).with(key: "reindex-#{dro.externalIdentifier}", lock_timeout: 30)
        expect(CocinaObjectStore).to have_received(:find).with(dro.externalIdentifier, validate: false)
        expect(Indexer).to have_received(:reindex).with(cocina_object: dro, trace_id:, current_as_of:)
      end
    end
  end
end
