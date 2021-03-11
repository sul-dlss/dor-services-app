# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroy Object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(DeleteService).to receive(:destroy).and_return(nil)
  end

  context 'when the request is successful' do
    it 'returns a 204 response' do
      delete "/v1/objects/#{druid}", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(204)
    end
  end

  context 'when the request fails' do
    before do
      allow(DeleteService).to receive(:destroy).and_raise('Broke destroy call')
    end

    it 'returns a 500 response' do
      delete "/v1/objects/#{druid}", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(500)
      expect(response.message).to eq 'Internal Server Error'
    end
  end
end
