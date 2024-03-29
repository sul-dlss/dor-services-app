# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateDoiMetadataJob do
  subject(:perform) do
    described_class.perform_now(cocina_item.to_json)
  end

  let(:cocina_item) do
    Cocina::Models.build({
                           'externalIdentifier' => 'druid:bc123df4567',
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
                             doi: '10.80343/bc123df4567',
                             sourceId: 'sul:123'
                           }
                         })
  end

  let(:attributes) { { titles: [{ title: 'test deposit' }] } }

  context 'with no errors' do
    before do
      allow(Cocina::ToDatacite::Attributes).to receive(:mapped_from_cocina).and_return(attributes)
      stub_request(:put, 'https://fake.datacite.example.com/dois/10.80343/bc123df4567')
        .with(
          body: '{"data":{"attributes":{"titles":[{"title":"test deposit"}]}}}'
        )
        .to_return(status: 200, body: '', headers: {})
    end

    it 'is successful' do
      expect { perform }.not_to raise_error
    end
  end

  context 'with a remote error' do
    before do
      allow(Cocina::ToDatacite::Attributes).to receive(:mapped_from_cocina).and_return(attributes)
      stub_request(:put, 'https://fake.datacite.example.com/dois/10.80343/bc123df4567')
        .with(
          body: '{"data":{"attributes":{"titles":[{"title":"test deposit"}]}}}'
        )
        .to_return(status: 500, body: '', headers: {})
    end

    it 'raises an error' do
      expect { perform }.to raise_error RuntimeError
    end
  end
end
