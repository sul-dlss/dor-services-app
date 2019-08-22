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

  describe '/publish' do
    it 'calls PublishMetadataService and returns 201' do
      expect(PublishMetadataService).to receive(:publish).with(item)
      post :publish, params: { id: item.pid }
      expect(response.status).to eq(201)
    end

    context 'with bad metadata' do
      let(:error_message) { "DublinCoreService#ng_xml produced incorrect xml (no children):\n<xml/>" }

      it 'returns a 400 error' do
        allow(PublishMetadataService).to receive(:publish).and_raise(DublinCoreService::CrosswalkError, error_message)
        post :publish, params: { id: item.pid }
        expect(response.status).to eq(400)
        expect(response.body).to eq(error_message)
      end
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
    let(:fake_request) { "<stanfordCreationRequest><objectId>#{item.pid}</objectId></stanfordCreationRequest>" }

    before do
      allow_any_instance_of(Dor::Goobi).to receive(:xml_request).and_return fake_request
    end

    context 'when it is successful' do
      before do
        stub_request(:post, Settings.goobi.url)
          .to_return(body: fake_request,
                     headers: { 'Content-Type' => 'application/xml' },
                     status: 201)
      end

      it 'notifies goobi of a new registration by making a web service call' do
        post :notify_goobi, params: { id: item.pid }
        expect(response.status).to eq(201)
      end
    end

    context 'when it is a conflict' do
      before do
        stub_request(:post, Settings.goobi.url)
          .to_return(body: 'conflict',
                     status: 409)
      end

      it 'returns the conflict code' do
        post :notify_goobi, params: { id: item.pid }
        expect(response.status).to eq(409)
        expect(response.body).to eq('conflict')
      end
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
end
