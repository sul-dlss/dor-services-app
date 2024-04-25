# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexByDruidJob do
  let(:message) { { druid: }.to_json }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }

  context 'when object is found' do
    before do
      allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
      allow(Indexer).to receive(:reindex)
    end

    it 'updates the druid' do
      described_class.new.work(message)
      expect(Indexer).to have_received(:reindex).with(cocina_object:)
    end
  end

  context 'when object is not found' do
    before do
      allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      allow(Honeybadger).to receive(:notify)
      allow(Indexer).to receive(:reindex)
    end

    it 'does not update the druid' do
      described_class.new.work(message)
      expect(Honeybadger).to have_received(:notify)
      expect(Indexer).not_to have_received(:reindex)
    end
  end
end
