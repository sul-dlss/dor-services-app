# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynchronousIndexer do
  subject(:reindex) { described_class.reindex_remotely(pid) }

  let(:pid) { 'druid:bc123dg4893' }

  context 'with a successful request' do
    before do
      stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:bc123dg4893')
        .to_return(status: 200, body: '', headers: {})
    end

    it { is_expected.to be_nil }
  end

  context 'with an unsuccessful request' do
    before do
      allow(Honeybadger).to receive(:notify)
      stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:bc123dg4893')
        .to_return(status: 500, body: 'broken', headers: {})
    end

    it 'logs an error' do
      reindex
      expect(Honeybadger).to have_received(:notify)
        .with('Response for reindexing was an error. 500: broken', druid: 'druid:bc123dg4893')
    end
  end
end
