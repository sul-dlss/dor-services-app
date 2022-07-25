# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroy Object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

  let(:params) do
    {
      user_name: 'some_person'
    }
  end

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(DeleteService).to receive(:destroy).and_return(nil)
  end

  context 'when the request is successful' do
    it 'returns a 204 response' do
      delete "/v1/objects/#{druid}",
             params: params,
             headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(DeleteService).to have_received(:destroy).with(cocina_object, **params)
    end
  end

  context 'when the request fails' do
    before do
      allow(DeleteService).to receive(:destroy).and_raise('Broke destroy call')
    end

    it 'returns a 500 response' do
      delete "/v1/objects/#{druid}",
             params: params,
             headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:internal_server_error)
      expect(response.message).to eq 'Internal Server Error'
    end
  end
end
