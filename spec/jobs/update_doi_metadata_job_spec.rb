# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateDoiMetadataJob do
  subject(:perform) { described_class.perform_now(cocina_item.to_json) }

  let(:attributes) { { titles: [{ title: 'test deposit' }] } }
  let(:cocina_item) do
    Cocina::Models.build({
                           'externalIdentifier' => druid,
                           'type' => Cocina::Models::ObjectType.image,
                           'version' => 1,
                           'label' => 'testing',
                           'access' => {},
                           'administrative' => {
                             'hasAdminPolicy' => 'druid:xx123xx4567'
                           },
                           'description' => {
                             'title' => [{ 'value' => 'Test obj' }],
                             'purl' => 'https://purl.stanford.edu/bc123df4567',
                             'subject' => [{ 'type' => 'topic', 'value' => 'word' }]
                           },
                           'structural' => {
                             'contains' => []
                           },
                           identification: {
                             doi:,
                             sourceId: 'sul:123'
                           }
                         })
  end
  let(:doi) { '10.80343/bc123df4567' }
  let(:druid) { 'druid:bc123df4567' }

  before do
    allow(Honeybadger).to receive(:context)
    allow(Cocina::ToDatacite::Attributes).to receive(:mapped_from_cocina).and_return(attributes)
    stub_request(:put, 'https://fake.datacite.example.com/dois/10.80343/bc123df4567')
      .with(
        body: '{"data":{"attributes":{"titles":[{"title":"test deposit"}]}}}'
      )
      .to_return(status: datacite_response_status, body: '', headers: {})
  end

  context 'with no errors' do
    let(:datacite_response_status) { 200 }

    it 'succeeds and injects helpful information into Honeybadger context' do
      expect { perform }.not_to raise_error
      expect(Honeybadger).to have_received(:context).once.with(
        attributes:,
        doi:,
        druid:
      )
    end
  end

  context 'with a remote error' do
    let(:datacite_response_status) { 500 }

    it 'raises an error and injects helpful information into Honeybadger context' do
      expect { perform }.to raise_error RuntimeError
      expect(Honeybadger).to have_received(:context).once.with(
        attributes:,
        doi:,
        druid:
      )
    end
  end
end
