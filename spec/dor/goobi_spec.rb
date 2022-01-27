# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::Goobi do
  let(:goobi) { described_class.new(dro) }
  let(:druid) { 'druid:jp670nd1791' }
  let(:barcode) { '6772719-1001' }
  let(:dro_props) do
    {
      externalIdentifier: druid,
      version: 1,
      type: Cocina::Models::Vocab.document,
      label: 'Object Title & A Special character',
      identification: {
        barcode: barcode,
        catalogLinks: [
          {
            catalog: 'symphony',
            catalogRecordId: 'ckey_12345'
          }
        ],
        sourceId: 'some:source_id'
      },
      access: {},
      administrative: {
        hasAdminPolicy: 'druid:dd999df4567'
      }
    }.tap do |props|
      props[:description] = description if description
    end
  end
  let(:dro) { Cocina::Models::DRO.new(dro_props) }

  let(:description) { nil }

  before do
    allow(AdministrativeTags).to receive(:content_type).with(pid: druid).and_return(['book'])
  end

  describe '#title_or_label' do
    subject(:title_or_label) { Nokogiri::XML(goobi.send(:xml_request)).xpath('//title').first.content }

    context 'when MODS title is present' do
      let(:description) do
        {
          title: [
            {
              value: 'Constituent label & A Special character'
            }
          ],
          purl: Purl.for(druid: druid)
        }
      end

      it 'returns title text' do
        expect(title_or_label).to eq 'Constituent label & A Special character'
      end
    end

    context 'when MODS title is absent or empty' do
      it 'returns object label' do
        expect(title_or_label).to eq 'Object Title & A Special character'
      end
    end
  end

  describe '#collection_name and id' do
    let(:collection_druid) { 'druid:dd999df4567' }

    let(:collection) do
      Cocina::Models::Collection.new({
                                       externalIdentifier: collection_druid,
                                       version: 1,
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'Collection label',
                                       access: {}
                                     })
    end

    context 'when part of collection' do
      before do
        dro_props[:structural] = { isMemberOf: [collection_druid] }
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
      end

      it 'returns collection name and id from a valid identityMetadata' do
        expect(goobi.send(:collection_name)).to eq('Collection label')
        expect(goobi.send(:collection_id)).to eq(collection_druid)
      end
    end

    context 'when not part of collection' do
      it 'returns blank for collection name and id' do
        expect(goobi.send(:collection_name)).to eq('')
        expect(goobi.send(:collection_id)).to eq('')
      end
    end
  end

  describe '#goobi_xml_tags' do
    subject { goobi.send(:goobi_xml_tags) }

    before do
      allow(AdministrativeTags).to receive(:for).and_return(tags)
    end

    context 'without ocr tag present' do
      let(:tags) { ['DPG : Workflow : book_workflow & stuff', 'Process : Content Type : Book', 'LAB : MAPS'] }

      it { is_expected.to eq('<tag name="DPG" value="Workflow : book_workflow &amp; stuff"/><tag name="Process" value="Content Type : Book"/><tag name="LAB" value="MAPS"/>') }
    end

    context 'with ocr tag present' do
      let(:tags) { ['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'] }

      it { is_expected.to eq('<tag name="DPG" value="Workflow : book_workflow"/><tag name="DPG" value="OCR : TRUE"/>') }
    end

    context 'with no tags present' do
      let(:tags) { [] }

      it { is_expected.to eq '' }
    end
  end

  describe '#goobi_workflow_name' do
    subject(:goobi_workflow_name) { goobi.send(:goobi_workflow_name) }

    it 'returns goobi_workflow_name from a valid identityMetadata' do
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(goobi_workflow_name).to eq('book_workflow')
    end

    it 'returns first goobi_workflow_name if multiple are in the tags' do
      allow(AdministrativeTags).to receive(:for)
        .and_return(['DPG : Workflow : book_workflow', 'DPG : Workflow : another_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(goobi_workflow_name).to eq('book_workflow')
    end

    it 'returns blank for goobi_workflow_name if none are found' do
      allow(AdministrativeTags).to receive(:for).and_return(['Process : Content Type : Book (flipbook, ltr)'])
      expect(goobi_workflow_name).to eq(Settings.goobi.default_goobi_workflow_name)
    end
  end

  describe '#goobi_tag_list' do
    let(:goobi_tag_list) { goobi.send(:goobi_tag_list) }

    it 'returns an array of arrays with the tags from the object in the key:value format expected to be passed to goobi' do
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)', 'LAB : Map Work'])
      expect(goobi_tag_list.length).to eq 3
      goobi_tag_list.each { |goobi_tag| expect(goobi_tag.class).to eq Dor::GoobiTag }
      expect(goobi_tag_list[0]).to have_attributes(name: 'DPG', value: 'Workflow : book_workflow')
      expect(goobi_tag_list[1]).to have_attributes(name: 'Process', value: 'Content Type : Book (flipbook, ltr)')
      expect(goobi_tag_list[2]).to have_attributes(name: 'LAB', value: 'Map Work')
    end

    it 'returns an empty array when there are no tags' do
      allow(AdministrativeTags).to receive(:for).and_return([])
      expect(goobi_tag_list).to eq []
    end

    it 'works with singleton tags (no colon, so no value, just a name)' do
      allow(AdministrativeTags).to receive(:for).and_return(['Name : Some Value', 'JustName'])
      expect(goobi_tag_list.length).to eq 2
      expect(goobi_tag_list[0].class).to eq Dor::GoobiTag
      expect(goobi_tag_list[0]).to have_attributes(name: 'Name', value: 'Some Value')
      expect(goobi_tag_list[1]).to have_attributes(name: 'JustName', value: nil)
    end
  end

  describe '#goobi_ocr_tag_present?' do
    let(:goobi_ocr_tag_present) { goobi.send(:goobi_ocr_tag_present?) }

    it 'returns false if the goobi ocr tag is not present' do
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(goobi_ocr_tag_present).to be false
    end

    it 'returns true if the goobi ocr tag is present' do
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'])
      expect(goobi_ocr_tag_present).to be true
    end

    it 'returns true if the goobi ocr tag is present even if the case is mixed' do
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow', 'DPG : ocr : true'])
      expect(goobi_ocr_tag_present).to be true
    end
  end

  describe '#xml_request' do
    subject(:xml_request) { goobi.send(:xml_request) }

    before do
      allow(goobi).to receive(:goobi_workflow_name).and_return('goobi_workflow')
      allow(AdministrativeTags).to receive(:for).and_return(tags)
      allow(goobi).to receive(:collection_id).and_return('druid:oo000oo0001')
      allow(goobi).to receive(:collection_name).and_return('collection name')
      allow(goobi).to receive(:project_name).and_return('Project Name')
    end

    context 'without ocr tag present' do
      let(:tags) { ['DPG : Workflow : book_workflow & stuff', 'Process : Content Type : Book', 'LAB : MAPS'] }

      it 'creates the correct xml request' do
        expect(xml_request).to be_equivalent_to <<-END
          <stanfordCreationRequest>
            <objectId>#{druid}</objectId>
            <objectType>item</objectType>
            <sourceID>some:source_id</sourceID>
            <title>Object Title &amp; A Special character</title>
            <contentType>book</contentType>
            <project>Project Name</project>
            <catkey>ckey_12345</catkey>
            <barcode>#{barcode}</barcode>
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
    end

    context 'with ocr tag present' do
      let(:tags) { ['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'] }

      it 'creates the correct xml request' do
        expect(xml_request).to be_equivalent_to <<-END
          <stanfordCreationRequest>
            <objectId>#{druid}</objectId>
            <objectType>item</objectType>
            <sourceID>some:source_id</sourceID>
            <title>Object Title &amp; A Special character</title>
            <contentType>book</contentType>
            <project>Project Name</project>
            <catkey>ckey_12345</catkey>
            <barcode>#{barcode}</barcode>
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
    end

    context 'with no tags present' do
      let(:tags) { [] }

      let(:description) do
        {
          title: [
            {
              value: 'Constituent label & A Special character'
            }
          ],
          purl: Purl.for(druid: druid)
        }
      end

      it 'creates the correct xml request when MODs title exists with a special character' do
        expect(xml_request).to be_equivalent_to <<-END
          <stanfordCreationRequest>
            <objectId>#{druid}</objectId>
            <objectType>item</objectType>
            <sourceID>some:source_id</sourceID>
            <title>Constituent label &amp; A Special character</title>
            <contentType>book</contentType>
            <project>Project Name</project>
            <catkey>ckey_12345</catkey>
            <barcode>#{barcode}</barcode>
            <collectionId>druid:oo000oo0001</collectionId>
            <collectionName>collection name</collectionName>
            <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
            <goobiWorkflow>goobi_workflow</goobiWorkflow>
            <ocr>false</ocr>
            <tags></tags>
          </stanfordCreationRequest>
        END
      end
    end
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

  describe '#content_type' do
    subject(:content_type) { goobi.send :content_type }

    it 'returns the content_type_tag from tag service if the value exists' do
      allow(AdministrativeTags).to receive(:content_type).and_return(['Process Value'])
      expect(content_type).to eq 'Process Value'
    end

    it 'returns the type from cocina if content_type from tag service does not have a value' do
      allow(AdministrativeTags).to receive(:content_type).and_return([])
      expect(content_type).to eq 'document'
    end
  end

  describe '#project_name' do
    subject(:project_name) { goobi.send :project_name }

    it 'returns project name from a valid identityMetadata' do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : Batchelor Maps : Batch 1', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(project_name).to eq('Batchelor Maps : Batch 1')
    end

    it 'returns blank for project name if not in tag' do
      allow(AdministrativeTags).to receive(:for).and_return(['Process : Content Type : Book (flipbook, ltr)'])
      expect(project_name).to eq('')
    end
  end
end
