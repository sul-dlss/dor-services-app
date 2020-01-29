# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a workspace' do
  let(:item) { Dor::Item.new(pid: 'druid:mx123qw2323') }

  before do
    allow(Dor).to receive(:find).and_return(item)
    rights_metadata_xml = Dor::RightsMetadataDS.new
    allow(rights_metadata_xml).to receive_messages(ng_xml: Nokogiri::XML('<xml/>'))
    allow(item).to receive_messages(
      id: 'druid:mx123qw2323',
      datastreams: { 'rightsMetadata' => rights_metadata_xml },
      rightsMetadata: rights_metadata_xml
    )
    allow(rights_metadata_xml).to receive(:dra_object).and_return(Dor::RightsAuth.parse(Nokogiri::XML('<xml/>'), true))
    clean_workspace
  end

  after do
    clean_workspace
  end

  it 'creates a druid tree in the dor workspace for the passed in druid' do
    post '/v1/objects/druid:mx123qw2323/workspace',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(File).to be_directory(TEST_WORKSPACE + '/mx/123/qw/2323')
  end

  it 'creates a link in the dor workspace to the path passed in as source' do
    post '/v1/objects/druid:mx123qw2323/workspace',
         params: { source: '/some/path' },
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(File).to be_symlink(TEST_WORKSPACE + '/mx/123/qw/2323/mx123qw2323')
  end

  context 'when the link/directory already exists' do
    before do
      druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
      druid.mkdir
    end

    it 'returns a 409 Conflict http status code' do
      post '/v1/objects/druid:mx123qw2323/workspace',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(409)
      expect(response.body).to match(/The directory already exists/)
    end
  end

  context 'when the workspace already exists with different content' do
    before do
      druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
      druid.mkdir
    end

    it 'returns a 409 Conflict http status code' do
      post '/v1/objects/druid:mx123qw2323/workspace',
           params: { source: '/some/path' },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(409)
      expect(response.body).to match(/Unable to create link, directory already exists/)
    end
  end
end
