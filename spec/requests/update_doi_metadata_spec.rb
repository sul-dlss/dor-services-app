# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update DOI metadata' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  it 'responds to the request with 202 ("accepted")' do
    post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response.status).to eq(202)
  end
end
