# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkspacesController do
  let(:item) { Dor::Item.new(pid: 'druid:aa123bb4567') }

  describe '#create' do
    before do
      login
      allow(Dor).to receive(:find).and_return(item)
      rights_metadata_xml = Dor::RightsMetadataDS.new
      allow(rights_metadata_xml).to receive_messages(ng_xml: Nokogiri::XML('<xml/>'))
      allow(item).to receive_messages(
        id: 'druid:aa123bb4567',
        datastreams: { 'rightsMetadata' => rights_metadata_xml },
        rightsMetadata: rights_metadata_xml,
        remove_druid_prefix: 'aa123bb4567'
      )
      allow(rights_metadata_xml).to receive(:dra_object).and_return(Dor::RightsAuth.parse(Nokogiri::XML('<xml/>'), true))
      clean_workspace
    end

    after do
      clean_workspace
    end

    it 'creates a druid tree in the dor workspace for the passed in druid' do
      post :create, params: { id: item.pid }
      expect(File).to be_directory(TEST_WORKSPACE + '/aa/123/bb/4567')
    end

    it 'creates a link in the dor workspace to the path passed in as source' do
      post :create, params: { id: item.pid, source: '/some/path' }
      expect(File).to be_symlink(TEST_WORKSPACE + '/aa/123/bb/4567/aa123bb4567')
    end

    context 'when the link/directory already exists' do
      before do
        druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
        DruidPath.new(druid: druid).mkdir
      end

      it 'returns a 409 Conflict http status code' do
        post :create, params: { id: item.pid }
        expect(response.status).to eq(409)
        expect(response.body).to match(/The directory already exists/)
      end
    end

    context 'when the workspace already exists with different content' do
      before do
        druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
        DruidPath.new(druid: druid).mkdir
      end

      it 'returns a 409 Conflict http status code' do
        post :create, params: { id: item.pid, source: '/some/path' }
        expect(response.status).to eq(409)
        expect(response.body).to match(/Unable to create link, directory already exists/)
      end
    end
  end

  describe '#destroy' do
    before do
      login
      allow(CleanupService).to receive(:cleanup_by_druid)
    end

    let(:druid) { 'druid:aa222cc3333' }

    it 'is successful' do
      delete :destroy, params: { object_id: druid }
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid)
      expect(response).to be_no_content
    end
  end
end
