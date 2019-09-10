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

  describe '/publish' do
    it 'calls PublishMetadataService and returns 201' do
      expect(PublishMetadataService).to receive(:publish).with(item)
      post :publish, params: { id: item.pid }
      expect(response.status).to eq(201)
    end

    context 'with bad metadata' do
      let(:error_message) { "DublinCoreService#ng_xml produced incorrect xml (no children):\n<xml/>" }

      it 'returns a 500 error' do
        allow(PublishMetadataService).to receive(:publish).and_raise(DublinCoreService::CrosswalkError, error_message)
        post :publish, params: { id: item.pid }
        expect(response.status).to eq(500)
        expect(response.body).to eq(error_message)
      end
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
end
