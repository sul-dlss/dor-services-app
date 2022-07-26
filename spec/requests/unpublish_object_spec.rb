# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Unpublishes an Object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { build(:ar_dro, external_identifier: druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(object)
  end

  context 'when an unpublish request is successful' do
    it 'returns a 202 response' do
      post "/v1/objects/#{druid}/unpublish", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:accepted)
    end
  end
end
