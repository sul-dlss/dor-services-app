# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Status (okcomputer)' do
  describe 'for application health' do
    it 'is successful' do
      get '/status'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'for Folio connection' do
    before do
      allow(Catalog::FolioReader).to receive(:to_marc).and_return('some marc stuff')
      allow(Settings.enabled_features).to receive(:read_folio).and_return(true)
    end

    it 'is successful' do
      get '/status/external-folio'
      expect(response).to have_http_status(:ok)
    end
  end
end
