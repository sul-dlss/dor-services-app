# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynchronousIndexer do
  describe '.reindex_remotely_from_cocina' do
    subject(:reindex) { described_class.reindex_remotely_from_cocina(cocina_object: cocina_object, created_at: created_at, updated_at: created_at) }

    let(:dro) { create(:dro) }
    let(:cocina_object) { dro.to_cocina }
    let(:created_at) { Time.zone.now }
    let(:req_body) { { cocina_object: cocina_object, created_at: created_at, updated_at: created_at }.to_json }

    context 'with a successful request' do
      before do
        stub_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina')
          .with(body: req_body, headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '', headers: {})
      end

      it { is_expected.to be_nil }
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
