require 'spec_helper'

describe Dor::Goobi do
  let(:pid) { 'druid:aa123bb4567' }
  let(:item) { Dor::Item.new(pid: pid) }

  before(:each) do
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
  it 'should create the correct xml request' do
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
      </stanfordCreationRequest>
    END
  end
  xit 'should make a call to the goobi server with the appropriate xml params' do
  end
end
