# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynchronousIndexer do
  describe '.reindex_remotely_from_cocina' do
    subject(:reindex) { described_class.reindex_remotely_from_cocina(cocina_object:, created_at:, updated_at: created_at) }

    let(:dro) { create(:ar_dro) }
    let(:cocina_object) { build(:dro) }
    let(:created_at) { Time.zone.now }
    let(:req_body) { { cocina_object: Cocina::Models.without_metadata(cocina_object), created_at:, updated_at: created_at }.to_json }

    context 'with a successful request' do
      before do
        stub_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina')
          .with(body: req_body, headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '', headers: {})
      end

      context 'with a DRO' do
        it { is_expected.to be_nil }
      end

      context 'with a DROWithMetadata' do
        let(:cocina_object) { build(:dro_with_metadata) }

        it { is_expected.to be_nil }
      end
    end

    context 'with an unsuccessful request' do
      before do
        allow(Honeybadger).to receive(:notify)
        stub_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina')
          .with(body: req_body)
          .to_return(status: 500, body: 'broken', headers: {})
      end

      it 'logs an error' do
        reindex
        expect(Honeybadger).to have_received(:notify)
          .with('Response for reindexing was an error. 500: broken', druid: cocina_object.externalIdentifier)
      end
    end
  end
end
