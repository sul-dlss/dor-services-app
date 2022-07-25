# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release tags' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 3) }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)

    ObjectVersion.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
    ObjectVersion.create(druid:, version: 2, tag: '2.0.0', description: 'pre-assembly re-accession')
    ObjectVersion.create(druid:, version: 3, tag: '3.0.0', description: 'pre-assembly re-accession')
  end

  it 'returns a 200' do
    get "/v1/objects/#{druid}/versions",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq '{"versions":[{"versionId":1,"tag":"1.0.0","message":"Initial Version"},' \
                                '{"versionId":2,"tag":"2.0.0","message":"pre-assembly re-accession"},' \
                                '{"versionId":3,"tag":"3.0.0","message":"pre-assembly re-accession"}]}'
  end
end
