# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset workspace' do
  let(:item) { instance_double(Dor::Item, current_version: 2) }
  let(:druid) { 'druid:aa222cc3333' }

  before do
    allow(Dor).to receive(:find).and_return(item)
  end

  context 'when the request is succcessful' do
    before do
      allow(ResetWorkspaceService).to receive(:reset)
    end

    it 'is successful' do
      post "/v1/objects/#{druid}/workspace/reset", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(ResetWorkspaceService).to have_received(:reset).with(druid: druid, version: 2)
      expect(response).to be_no_content
    end
  end

  context 'when an archive directory exists' do
    let(:errmsg) { '{"errors":[{"status":"422","title":"Archive directory already exists","detail":"dir already exists"}]}' }

    before do
      allow(ResetWorkspaceService).to receive(:reset)
        .and_raise(ResetWorkspaceService::DirectoryAlreadyExists.new('dir already exists'))
    end

    it 'returns a 422 error' do
      post "/v1/objects/#{druid}/workspace/reset", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(422)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when an archive bag exists' do
    let(:errmsg) { '{"errors":[{"status":"422","title":"Archive bag already exists","detail":"bag already exists"}]}' }

    before do
      allow(ResetWorkspaceService).to receive(:reset)
        .and_raise(ResetWorkspaceService::BagAlreadyExists.new('bag already exists'))
    end

    it 'returns a 422 error' do
      post "/v1/objects/#{druid}/workspace/reset", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(422)
      expect(response.body).to eq(errmsg)
    end
  end
end
