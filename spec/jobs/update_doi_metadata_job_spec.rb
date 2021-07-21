# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateDoiMetadataJob, type: :job do
  subject(:perform) do
    described_class.perform_now(cocina_item)
  end

  let(:cocina_item) do
    instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:bc123df4567',
                                         identification: instance_double(Cocina::Models::Identification, doi: '10.0001/bc123df4567'))
  end
  let(:attributes) { { titles: [{ title: 'test deposit' }] } }

  context 'with no errors' do
    before do
      allow(Cocina::ToDatacite::Attributes).to receive(:mapped_from_cocina).and_return(attributes)
      stub_request(:put, 'https://fake.datacite.example.com/dois/10.0001/bc123df4567')
        .with(
          body: '{"data":{"attributes":{"titles":[{"title":"test deposit"}]}}}'
        )
        .to_return(status: 200, body: '', headers: {})
    end

    it 'is successful' do
      perform
    end
  end

  context 'with a remote error' do
    before do
      allow(Cocina::ToDatacite::Attributes).to receive(:mapped_from_cocina).and_return(attributes)
      stub_request(:put, 'https://fake.datacite.example.com/dois/10.0001/bc123df4567')
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
