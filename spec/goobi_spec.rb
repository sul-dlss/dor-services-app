require 'rails_helper'

RSpec.describe Dor::Goobi do
  let(:pid) { 'druid:aa123bb4567' }
  let(:item) { Dor::Item.new(pid: pid) }

  before do
    # all of the methods we are stubbing out below are tested elsewhere,
    #  this just lets us test the methods in goobi.rb without doing a lot of setup
    allow(Dor::Item).to receive(:find).and_return(item)
    allow(item).to receive(:source_id).and_return('some_source_id')
    allow(item).to receive(:label).and_return('Object Title')
    allow(item).to receive(:content_type_tag).and_return('book')
    @goobi = Dor::Goobi.new(item)
    allow(@goobi).to receive(:project_name).and_return('Project Name')
    allow(@goobi).to receive(:object_type).and_return('item')
    allow(@goobi).to receive(:ckey).and_return('ckey_12345')
    allow(@goobi).to receive(:goobi_workflow_name).and_return('goobi_workflow')
    allow(@goobi).to receive(:barcode).and_return('barcode_12345')
    allow(@goobi).to receive(:collection_id).and_return('druid:oo000oo0001')
    allow(@goobi).to receive(:collection_name).and_return('collection name')
  end

  it 'creates the correct xml request without ocr tag present' do
    allow(item).to receive(:tags).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book', 'LAB : MAPS'])
    expect(@goobi.goobi_xml_tags).to eq('<tag name="DPG" value="Workflow : book_workflow"></tag><tag name="Process" value="Content Type : Book"></tag><tag name="LAB" value="MAPS"></tag>')
    expect(@goobi.xml_request).to be_equivalent_to <<-END
      <stanfordCreationRequest>
        <objectId>#{pid}</objectId>
        <objectType>item</objectType>
        <sourceID>some_source_id</sourceID>
        <title>Object Title</title>
        <contentType>book</contentType>
        <project>Project Name</project>
        <catkey>ckey_12345</catkey>
        <barcode>barcode_12345</barcode>
        <collectionId>druid:oo000oo0001</collectionId>
        <collectionName>collection name</collectionName>
        <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
        <goobiWorkflow>goobi_workflow</goobiWorkflow>
        <ocr>false</ocr>
        <tags>
            <tag name="DPG" value="Workflow : book_workflow"></tag>
            <tag name="Process" value="Content Type : Book"></tag>
            <tag name="LAB" value="MAPS"></tag>
        </tags>
      </stanfordCreationRequest>
    END
  end

  it 'creates the correct xml request with ocr tag present' do
    allow(item).to receive(:tags).and_return(['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'])
    expect(@goobi.goobi_xml_tags).to eq('<tag name="DPG" value="Workflow : book_workflow"></tag><tag name="DPG" value="OCR : TRUE"></tag>')
    expect(@goobi.xml_request).to be_equivalent_to <<-END
      <stanfordCreationRequest>
        <objectId>#{pid}</objectId>
        <objectType>item</objectType>
        <sourceID>some_source_id</sourceID>
        <title>Object Title</title>
        <contentType>book</contentType>
        <project>Project Name</project>
        <catkey>ckey_12345</catkey>
        <barcode>barcode_12345</barcode>
        <collectionId>druid:oo000oo0001</collectionId>
        <collectionName>collection name</collectionName>
        <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
        <goobiWorkflow>goobi_workflow</goobiWorkflow>
        <ocr>true</ocr>
        <tags>
            <tag name="DPG" value="Workflow : book_workflow"></tag>
            <tag name="DPG" value="OCR : TRUE"></tag>
        </tags>
      </stanfordCreationRequest>
    END
  end

  it 'creates the correct xml request with no tags present' do
    allow(item).to receive(:tags).and_return([])
    expect(@goobi.goobi_xml_tags).to eq('')
    expect(@goobi.xml_request).to include('<tags></tags>')
  end

  it 'makes a call to the goobi server with the appropriate xml params' do
    stub_request(:post, Dor::Config.goobi.url).to_return(body: '<somexml/>', headers: { 'Content-Type' => 'text/xml' })
    expect(@goobi).to receive(:xml_request)
    response = @goobi.register
    expect(response.code).to eq(200)
  end
end
