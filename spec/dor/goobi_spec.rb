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
    allow(item).to receive(:content_type_tag).and_return('book')
    allow(goobi).to receive(:project_name).and_return('Project Name')
    allow(goobi).to receive(:object_type).and_return('item')
    allow(goobi).to receive(:ckey).and_return('ckey_12345')
    allow(goobi).to receive(:goobi_workflow_name).and_return('goobi_workflow')
    allow(goobi).to receive(:barcode).and_return('barcode_12345')
    allow(goobi).to receive(:collection_id).and_return('druid:oo000oo0001')
    allow(goobi).to receive(:collection_name).and_return('collection name')
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
    allow(item).to receive(:tags).and_return(['DPG : Workflow : book_workflow & stuff', 'Process : Content Type : Book', 'LAB : MAPS'])
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
        <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
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
    allow(item).to receive(:tags).and_return(['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'])
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
        <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
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
        <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
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

  # rubocop:disable RSpec/SubjectStub
  it 'makes a call to the goobi server with the appropriate xml params' do
    stub_request(:post, Dor::Config.goobi.url).to_return(body: '<somexml/>', headers: { 'Content-Type' => 'text/xml' })
    expect(goobi).to receive(:xml_request)
    response = goobi.register
    expect(response.code).to eq(200)
  end
  # rubocop:enable RSpec/SubjectStub
end
