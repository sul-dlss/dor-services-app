# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MARC record' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when the request is successful' do
    it 'returns a 201 response' do
      post "/v1/objects/#{druid}/update_marc_record", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(201)
    end
  end
end
