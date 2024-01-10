# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the members' do
  let(:collection_druid) { 'druid:mk420bs7601' }

  let!(:dro) { create(:ar_dro, isMemberOf: [collection_druid]) }

  let(:expected) do
    {
      members: [
        {
          externalIdentifier: dro.external_identifier,
          version: dro.version
        }
      ]
    }
  end

  it 'returns the druids' do
    get "/v1/objects/#{collection_druid}/members",
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(expected)
  end
end
