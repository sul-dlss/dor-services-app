# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workspaces' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:path_to_workspace) { '/path/to/workspace' }

  before do
    allow(CocinaObjectStore).to receive(:exists!).and_return(true)
  end

  context 'when successful' do
    before do
      allow(WorkspaceService).to receive(:create).and_return(path_to_workspace)
    end

    context 'when no source is passed' do
      it 'is successful and returns the created directory' do
        post "/v1/objects/#{druid}/workspace",
             headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(WorkspaceService).to have_received(:create).with(druid, nil, content: nil, metadata: nil)
        expect(response).to have_http_status(:created)
        expect(response.body).to eq({ path: path_to_workspace }.to_json)
      end
    end

    context 'when content params are passed' do
      it 'is successful and returns the created directory' do
        post "/v1/objects/#{druid}/workspace?content=true",
             headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(WorkspaceService).to have_received(:create).with(druid, nil, content: true, metadata: nil)
        expect(response).to have_http_status(:created)
        expect(response.body).to eq({ path: path_to_workspace }.to_json)
      end
    end

    context 'when metadata params are passed' do
      it 'is successful and returns the created directory' do
        post "/v1/objects/#{druid}/workspace?metadata=true",
             headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(WorkspaceService).to have_received(:create).with(druid, nil, content: nil, metadata: true)
        expect(response).to have_http_status(:created)
        expect(response.body).to eq({ path: path_to_workspace }.to_json)
      end
    end

    context 'when content and metadata params are passed' do
      it 'is successful and returns the created directory' do
        post "/v1/objects/#{druid}/workspace?metadata=true&content=true",
             headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(WorkspaceService).to have_received(:create).with(druid, nil, content: true, metadata: true)
        expect(response).to have_http_status(:created)
        expect(response.body).to eq({ path: path_to_workspace }.to_json)
      end
    end

    context 'when source is passed' do
      let(:source) { '/path/to/source' }

      it 'is successful and returns the created directory' do
        post "/v1/objects/#{druid}/workspace?source=#{source}",
             headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(WorkspaceService).to have_received(:create).with(druid, source, content: nil, metadata: nil)
        expect(response).to have_http_status(:created)
        expect(response.body).to eq({ path: path_to_workspace }.to_json)
      end
    end
  end
end
