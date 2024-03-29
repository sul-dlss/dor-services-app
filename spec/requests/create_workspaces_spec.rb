# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a workspace' do
  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(CocinaObjectStore).to receive(:exists!).with(druid)
    clean_workspace
  end

  after do
    clean_workspace
  end

  it 'creates a druid tree in the dor workspace for the passed in druid' do
    post '/v1/objects/druid:mx123qw2323/workspace',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(File).to be_directory("#{TEST_WORKSPACE}/mx/123/qw/2323")
  end

  it 'creates a link in the dor workspace to the path passed in as source' do
    post '/v1/objects/druid:mx123qw2323/workspace',
         params: { source: '/some/path' },
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(File).to be_symlink("#{TEST_WORKSPACE}/mx/123/qw/2323/mx123qw2323")
  end

  context 'when the link/directory already exists' do
    before do
      DruidTools::Druid.new(druid, TEST_WORKSPACE).mkdir
    end

    it 'returns a 409 Conflict http status code' do
      post '/v1/objects/druid:mx123qw2323/workspace',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:conflict)
      expect(response.body).to match(/The directory already exists/)
    end
  end

  context 'when the workspace already exists with different content' do
    before do
      DruidTools::Druid.new(druid, TEST_WORKSPACE).mkdir
    end

    it 'returns a 409 Conflict http status code' do
      post '/v1/objects/druid:mx123qw2323/workspace',
           params: { source: '/some/path' },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:conflict)
      expect(response.body).to match(/Unable to create link, directory already exists/)
    end
  end
end
