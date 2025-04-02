# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexJob do
  subject(:perform) do
    described_class.perform_now(druid: dro.externalIdentifier, trace_id:)
  end

  let(:dro) { build(:dro) }
  let(:trace_id) { 'abc123' }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(dro)
  end

  context 'when no errors' do
    before do
      allow(Indexer).to receive(:reindex)
      allow(RedisLock).to receive(:lock).and_return(true)
      allow(RedisLock).to receive(:clear_lock)
    end

    it 'invokes the Indexer' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: dro, trace_id:)
      expect(RedisLock).to have_received(:lock).with(key: "reindex-#{dro.externalIdentifier}", lock_timeout: Integer)
      expect(RedisLock).to have_received(:clear_lock)
    end
  end

  context 'when an error' do
    before do
      allow(Indexer).to receive(:reindex).and_raise(CocinaObjectStore::CocinaObjectStoreError)
      allow(Honeybadger).to receive(:notify)
      allow(RedisLock).to receive(:lock).and_return(true)
      allow(RedisLock).to receive(:clear_lock)
    end

    it 'Honeybadger alerts' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: dro, trace_id:)
      expect(Honeybadger).to have_received(:notify)
      expect(RedisLock).to have_received(:lock)
      expect(RedisLock).to have_received(:clear_lock)
    end
  end

  context 'when getting a lock fails' do
    before do
      allow(RedisLock).to receive(:lock).and_return(false)
    end

    it 'raises' do
      expect do
        described_class.new.perform(druid: dro.externalIdentifier, trace_id:)
      end.to raise_error(ReindexJob::DeadLockError)
    end
  end
end
