# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexJob do
  subject(:perform) do
    described_class.perform_now(model: dro.to_h, created: Time.zone.now, modified: Time.zone.now, trace_id:)
  end

  let(:dro) { build(:dro) }
  let(:trace_id) { 'abc123' }

  context 'when no errors' do
    before do
      allow(Indexer).to receive(:reindex)
    end

    it 'invokes the Indexer' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: an_instance_of(Cocina::Models::DROWithMetadata),
                                                      trace_id:)
    end
  end

  context 'when an error' do
    before do
      allow(Indexer).to receive(:reindex).and_raise(CocinaObjectStore::CocinaObjectStoreError)
      allow(Honeybadger).to receive(:notify)
    end

    it 'Honeybadger alerts' do
      perform
      expect(Indexer).to have_received(:reindex).with(cocina_object: an_instance_of(Cocina::Models::DROWithMetadata),
                                                      trace_id:)
      expect(Honeybadger).to have_received(:notify)
    end
  end
end
