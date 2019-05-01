# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectsController do
  before do
    login
  end

  let(:item) { Dor::Item.new(pid: 'druid:aa123bb4567') }

  before do
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
  end

  describe 'object registration' do
    render_views

    context 'error handling' do
      it 'returns a 409 error with location header when an object already exists' do
        allow(RegistrationService).to receive(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))
        post :create
        expect(response.status).to eq(409)
        expect(response.headers['Location']).to match(%r{/fedora/objects/druid:existing123obj})
      end

      it 'returns a 422 error when an object has a bad name' do
        allow(RegistrationService).to receive(:register_object).and_raise(ArgumentError)
        post :create
        expect(response.status).to eq(422)
      end
    end

    it 'registers the object with the registration service' do
      allow(RegistrationService).to receive(:create_from_request).and_return(pid: 'druid:xyz')

      post :create

      expect(response.body).to eq 'druid:xyz'
      expect(RegistrationService).to have_received(:create_from_request)
      expect(response.status).to eq(201)
      expect(response.location).to end_with '/fedora/objects/druid:xyz'
    end
  end

  describe 'initialize_workspace' do
    before do
      clean_workspace
    end

    after do
      clean_workspace
    end

    it 'creates a druid tree in the dor workspace for the passed in druid' do
      post 'initialize_workspace', params: { id: item.pid }
      expect(File).to be_directory(TEST_WORKSPACE + '/aa/123/bb/4567')
    end

    it 'creates a link in the dor workspace to the path passed in as source' do
      post 'initialize_workspace', params: { id: item.pid, source: '/some/path' }
      expect(File).to be_symlink(TEST_WORKSPACE + '/aa/123/bb/4567/aa123bb4567')
    end

    context 'error handling' do
      before do
        druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
        druid.mkdir
      end

      it 'returns a 409 Conflict http status code when the link/directory already exists' do
        post 'initialize_workspace', params: { id: item.pid }
        expect(response.status).to eq(409)
        expect(response.body).to match(/The directory already exists/)
      end

      it 'returns a 409 Conflict http status code when the workspace already exists with different content' do
        post 'initialize_workspace', params: { id: item.pid, source: '/some/path' }
        expect(response.status).to eq(409)
        expect(response.body).to match(/Unable to create link, directory already exists/)
      end
    end
  end

  describe '/publish' do
    it 'calls publish metadata' do
      expect(PublishMetadataService).to receive(:publish).with(item)
      post :publish, params: { id: item.pid }
      expect(response.status).to eq(201)
    end
  end

  describe '/update_marc_record' do
    it 'updates a marc record' do
      # TODO: add some more expectations
      post :update_marc_record, params: { id: item.pid }
      expect(response.status).to eq(201)
    end
  end

  describe '/notify_goobi' do
    it 'notifies goobi of a new registration by making a web service call' do
      fake_request = "<stanfordCreationRequest><objectId>#{item.pid}</objectId></stanfordCreationRequest>"
      stub_request(:post, Dor::Config.goobi.url).to_return(body: fake_request, headers: { 'Content-Type' => 'application/xml' }, status: 201)
      allow_any_instance_of(Dor::Goobi).to receive(:xml_request).and_return(fake_request)
      fake_response = double(RestClient::Response, headers: { content_type: 'text/xml' }, code: 201, body: '')
      expect_any_instance_of(Dor::Goobi).to receive(:register).once.and_return(fake_response)
      post :notify_goobi, params: { id: item.pid }
      expect(response.status).to eq(201)
    end
  end

  describe '/release_tags' do
    it 'adds a release tag when posted to with false' do
      expect(ReleaseTags).to receive(:create).with(Dor::Item, release: false, to: 'searchworks', who: 'carrickr', what: 'self')
      expect(item).to receive(:save)
      post :release_tags, params: { id: item.pid }, body: %( {"to":"searchworks","who":"carrickr","what":"self","release":false} )
      expect(response.status).to eq(201)
    end

    it 'adds a release tag when posted to with true' do
      expect(ReleaseTags).to receive(:create).with(Dor::Item, release: true, to: 'searchworks', who: 'carrickr', what: 'self')
      expect(item).to receive(:save)
      post :release_tags, params: { id: item.pid }, body: %( {"to":"searchworks","who":"carrickr","what":"self","release":true} )
      expect(response.status).to eq(201)
    end

    it 'errors when posted to with an invalid release attribute' do
      post :release_tags, params: { id: item.pid }, body: %( {"to":"searchworks","who":"carrickr","what":"self","release":"seven"} )
      expect(response.status).to eq(400)
    end

    it 'errors when posted to with a missing release attribute' do
      post :release_tags, params: { id: item.pid }, body: %( {"to":"searchworks","who":"carrickr","what":"self"} )
      expect(response.status).to eq(400)
    end
  end

  describe 'apo-workflow intialization' do
    it 'initiates assemblyWF' do
      expect(Dor::CreateWorkflowService).to receive(:create_workflow).with(item, name: 'assemblyWF')

      post 'apo_workflows', params: { id: item.pid, wf_name: 'assemblyWF' }
    end

    it "handles workflow names without 'WF' appended to the end" do
      expect(Dor::CreateWorkflowService).to receive(:create_workflow).with(item, name: 'accessionWF')
      post 'apo_workflows', params: { id: item.pid, wf_name: 'accession' }
    end
  end
end
