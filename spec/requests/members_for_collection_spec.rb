# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the members' do
  let(:collection_druid) { 'druid:mk420bs7601' }
  let(:expected) do
    {
      members: [
        {
          externalIdentifier: repository_object.external_identifier,
          version: repository_object.head_version.version
        }
      ]
    }
  end

  let(:repository_object) { create(:repository_object) }

  before do
    repository_object_version = create(:repository_object_version, version: 2, is_member_of: [collection_druid], repository_object:)
    repository_object.update!(head_version: repository_object_version, opened_version: repository_object_version)
  end

  it 'returns the druids' do
    get "/v1/objects/#{collection_druid}/members",
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(expected)
  end
end
