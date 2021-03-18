# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Datastreams' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  describe 'get a list' do
    before do
      object.datastreams['workflows'] = instance_double(ActiveFedora::Datastream, new?: false)
      object.versionMetadata.content = 'hello'
      allow(object.versionMetadata).to receive(:new?).and_return(false)
      object.contentMetadata.content = 'howdy'
      allow(object.contentMetadata).to receive(:new?).and_return(false)
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/metadata/datastreams",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.status).to eq(200)
      expect(response.body).to eq '[{"label":"Version Metadata","dsid":"versionMetadata","pid":"druid:mx123qw2323","size":null,"mimeType":"text/xml"},' \
        '{"label":"Content Metadata","dsid":"contentMetadata","pid":"druid:mx123qw2323","size":null,"mimeType":"text/xml"}]'
    end
  end

  describe 'get a single datastream' do
    let(:content) do
      <<~XML
        <versionMetadata objectId="druid:bq653yd1233">
          <version versionId="1" tag="1.0.0">
            <description>Initial Version</description>
          </version>
        </versionMetadata>
      XML
    end

    before do
      object.versionMetadata.content = content
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/metadata/datastreams/versionMetadata",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.status).to eq(200)
      expect(response.body).to eq content.chomp
    end
  end
end
