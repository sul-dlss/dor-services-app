# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release tags' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)

    object.versionMetadata.content = <<~XML
      <versionMetadata objectId="druid:bq653yd1233">
        <version versionId="1" tag="1.0.0">
          <description>Initial Version</description>
        </version>
        <version versionId="2" tag="2.0.0">
          <description>pre-assembly re-accession</description>
        </version>
        <version versionId="3" tag="3.0.0">
          <description>pre-assembly re-accession</description>
        </version>
      </versionMetadata>
    XML
  end

  it 'returns a 200' do
    get "/v1/objects/#{druid}/versions",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response.status).to eq(200)
    expect(response.body).to eq '{"versions":[{"versionId":1,"tag":"1.0.0","message":"Initial Version"},' \
                                '{"versionId":2,"tag":"2.0.0","message":"pre-assembly re-accession"},' \
                                '{"versionId":3,"tag":"3.0.0","message":"pre-assembly re-accession"}]}'
  end
end
