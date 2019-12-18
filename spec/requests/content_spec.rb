# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content' do
  before do
    # login
    allow(Settings.content).to receive(:content_base_dir).and_return(File.join(FIXTURES_PATH, 'dor_workspace'))
  end

  describe '#list' do
    it 'lists the files in the object directory' do
      get '/v1/objects/druid:kx420bs7601/contents',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to be_successful
      data = JSON.parse(response.body)

      expect(data['items'].length).to eq 1
      expect(data['items'].first['id']).to eq 'a'
    end

    it 'sends a 404 if the object directory does not exist' do
      get '/v1/objects/druid:zy987xw6543/contents',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#read' do
    it 'retrieves the contents of the given file' do
      get '/v1/objects/druid:kx420bs7601/contents/a',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to be_successful
      expect(response.body).to eq "a\n"
    end

    it 'sends a 404 if the file does not exist' do
      get '/v1/objects/druid:kx420bs7601/contents/a/b/c',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:not_found)
    end

    it 'sends a 404 on HEAD requests of the file does not exist' do
      head '/v1/objects/druid:kx420bs7601/contents/a/b/c',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
