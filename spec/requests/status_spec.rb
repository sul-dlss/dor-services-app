# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Status (okcomputer)' do
  describe 'for application health' do
    it 'is successful' do
      get '/status'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'for Symphony connection' do
    let(:symphony_client) { instance_double(Faraday::Connection, get: true) }

    before do
      allow(SymphonyReader).to receive(:client).and_return(symphony_client)
    end

    it 'is successful' do
      get '/status/external-symphony'
      expect(response).to have_http_status(:ok)
    end
  end
end
