# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::Goobi do
  subject(:goobi) { Dor::Goobi.new(item) }

  let(:pid) { 'druid:aa123bb4567' }
  let(:item) { Dor::Item.new(pid: pid) }

  # rubocop:disable RSpec/SubjectStub
  before do
    # all of the methods we are stubbing out below are tested elsewhere,
    #  this just lets us test the methods in goobi.rb without doing a lot of setup
    allow(Dor::Item).to receive(:find).and_return(item)
    allow(item).to receive(:source_id).and_return('some_source_id')
    allow(item).to receive(:label).and_return('Object Title & A Special character')
    allow(goobi).to receive(:project_name).and_return('Project Name')
    allow(goobi).to receive(:object_type).and_return('item')
    allow(goobi).to receive(:ckey).and_return('ckey_12345')
    allow(goobi).to receive(:goobi_workflow_name).and_return('goobi_workflow')
    allow(goobi).to receive(:barcode).and_return('barcode_12345')
    allow(goobi).to receive(:collection_id).and_return('druid:oo000oo0001')
    allow(goobi).to receive(:collection_name).and_return('collection name')
    allow(AdministrativeTags).to receive(:content_type).with(item: item).and_return(['book'])
  end
  # rubocop:enable RSpec/SubjectStub

  describe '#title_or_label' do
    subject(:xml) { Nokogiri::XML(goobi.xml_request).xpath('//title').first.content }

    context 'when MODS title is present' do
      before do
        item.datastreams['descMetadata'].ng_xml = build_desc_metadata_1
      end

      it 'returns title text' do
        expect(xml).to eq 'Constituent label & A Special character'
      end
    end

    context 'when MODS title is absent or empty' do
      it 'returns object label' do
        expect(xml).to eq 'Object Title & A Special character'
      end
    end
  end

  it 'creates the correct xml request without ocr tag present' do
    allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow & stuff', 'Process : Content Type : Book', 'LAB : MAPS'])
    expect(goobi.goobi_xml_tags).to eq('<tag name="DPG" value="Workflow : book_workflow &amp; stuff"/><tag name="Process" value="Content Type : Book"/><tag name="LAB" value="MAPS"/>')
    expect(goobi.xml_request).to be_equivalent_to <<-END
      <stanfordCreationRequest>
        <objectId>#{pid}</objectId>
        <objectType>item</objectType>
        <sourceID>some_source_id</sourceID>
        <title>Object Title &amp; A Special character</title>
        <contentType>book</contentType>
        <project>Project Name</project>
        <catkey>ckey_12345</catkey>
        <barcode>barcode_12345</barcode>
        <collectionId>druid:oo000oo0001</collectionId>
        <collectionName>collection name</collectionName>
        <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
        <goobiWorkflow>goobi_workflow</goobiWorkflow>
        <ocr>false</ocr>
        <tags>
            <tag name="DPG" value="Workflow : book_workflow &amp; stuff"/>
            <tag name="Process" value="Content Type : Book"/>
            <tag name="LAB" value="MAPS"/>
        </tags>
      </stanfordCreationRequest>
    END
  end

  it 'creates the correct xml request with ocr tag present' do
    allow(AdministrativeTags).to receive(:for).with(item: item).and_return(['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'])
    expect(goobi.goobi_xml_tags).to eq('<tag name="DPG" value="Workflow : book_workflow"/><tag name="DPG" value="OCR : TRUE"/>')
    expect(goobi.xml_request).to be_equivalent_to <<-END
      <stanfordCreationRequest>
        <objectId>#{pid}</objectId>
        <objectType>item</objectType>
        <sourceID>some_source_id</sourceID>
        <title>Object Title &amp; A Special character</title>
        <contentType>book</contentType>
        <project>Project Name</project>
        <catkey>ckey_12345</catkey>
        <barcode>barcode_12345</barcode>
        <collectionId>druid:oo000oo0001</collectionId>
        <collectionName>collection name</collectionName>
        <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
        <goobiWorkflow>goobi_workflow</goobiWorkflow>
        <ocr>true</ocr>
        <tags>
            <tag name="DPG" value="Workflow : book_workflow"/>
            <tag name="DPG" value="OCR : TRUE"/>
        </tags>
      </stanfordCreationRequest>
    END
  end

  it 'creates the correct xml request when MODs title exists with a special character' do
    item.datastreams['descMetadata'].ng_xml = build_desc_metadata_1
    expect(goobi.xml_request).to be_equivalent_to <<-END
      <stanfordCreationRequest>
        <objectId>#{pid}</objectId>
        <objectType>item</objectType>
        <sourceID>some_source_id</sourceID>
        <title>Constituent label &amp; A Special character</title>
        <contentType>book</contentType>
        <project>Project Name</project>
        <catkey>ckey_12345</catkey>
        <barcode>barcode_12345</barcode>
        <collectionId>druid:oo000oo0001</collectionId>
        <collectionName>collection name</collectionName>
        <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
        <goobiWorkflow>goobi_workflow</goobiWorkflow>
        <ocr>false</ocr>
        <tags></tags>
      </stanfordCreationRequest>
    END
  end

  it 'creates the correct xml request with no tags present' do
    allow(item).to receive(:tags).and_return([])
    expect(goobi.goobi_xml_tags).to eq('')
    expect(goobi.xml_request).to include('<tags></tags>')
  end

  describe '#register' do
    subject(:response) { goobi.register }

    before do
      allow(goobi).to receive(:xml_request)
    end

    context 'with a successful response' do
      before do
        stub_request(:post, Settings.goobi.url)
          .to_return(body: '<somexml/>', headers: { 'Content-Type' => 'text/xml' }, status: 201)
      end

      it 'makes a call to the goobi server with the appropriate xml params' do
        expect(response.status).to eq 201
      end
    end

    context 'with a 409 response' do
      before do
        allow(Faraday).to receive(:post).and_call_original
        stub_request(:post, Settings.goobi.url)
          .to_return(body: '<somexml/>', headers: { 'Content-Type' => 'text/xml' }, status: 409)
      end

      it 'makes a call to the goobi server with the appropriate xml params' do
        expect(response.status).to eq 409
        expect(Faraday).to have_received(:post).once # Don't retry request errors
      end
    end
  end
end
