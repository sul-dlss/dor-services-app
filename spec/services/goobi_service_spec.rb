# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoobiService do
  let(:goobi) { described_class.new(dro) }
  let(:druid) { 'druid:jp670nd1791' }
  let(:barcode) { '6772719-1001' }
  let(:dro_props) do
    {
      externalIdentifier: druid,
      version: 1,
      type: Cocina::Models::ObjectType.book,
      label: 'Object Title & A Special character',
      description: {
        title: [{ value: 'Object Title & A Special character' }],
        purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
      },
      identification: {
        barcode:,
        catalogLinks: [
          {
            catalog: 'folio',
            catalogRecordId: 'a11403803',
            refresh: true
          }
        ],
        sourceId: 'some:source_id'
      },
      access: {},
      administrative: {
        hasAdminPolicy: 'druid:dd999df4567'
      },
      structural: {}
    }.tap do |props|
      props[:description] = description if description
    end
  end
  let(:dro) { Cocina::Models::DRO.new(dro_props) }

  let(:description) { nil }

  describe '#title_or_label' do
    subject(:title_or_label) { Nokogiri::XML(goobi.send(:xml_request)).xpath('//title').first.content }

    context 'when description is present' do
      let(:description) do
        {
          title: [
            {
              value: 'Constituent label & A Special character'
            }
          ],
          purl: Purl.for(druid:)
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
                                       type: Cocina::Models::ObjectType.collection,
                                       label: 'Collection label',
                                       description: {
                                         title: [{ value: 'Collection label' }],
                                         purl: "https://purl.stanford.edu/#{collection_druid.delete_prefix('druid:')}"
                                       },
                                       access: {},
                                       administrative: {
                                         hasAdminPolicy: 'druid:dd999df4567'
                                       },
                                       identification: { sourceId: 'sul:123' }
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
    subject(:result) { goobi.send(:goobi_xml_tags) }

    before do
      allow(AdministrativeTags).to receive(:for).and_return(tags)
    end

    context 'without ocr tag present' do
      let(:tags) { ['DPG : Workflow : book_workflow & stuff', 'LAB : MAPS'] }

      it {
        expect(result).to eq('<tag name="DPG" value="Workflow : book_workflow &amp; stuff"/><tag name="LAB" value="MAPS"/>') # rubocop:disable Layout/LineLength
      }
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

    before do
      allow(AdministrativeTags).to receive(:for).and_return(tags)
    end

    context 'with a single tag' do
      let(:tags) { ['DPG : Workflow : book_workflow', 'LAB : MAPS'] }

      it 'returns value parsed from a DPG admin tag' do
        expect(goobi_workflow_name).to eq('book_workflow')
      end
    end

    context 'with multiple tags' do
      let(:tags) do
        ['DPG : Workflow : book_workflow', 'DPG : Workflow : another_workflow',
         'LAB : MAPS']
      end

      it 'returns value parsed from first DPG admin tag' do
        expect(goobi_workflow_name).to eq('book_workflow')
      end
    end

    context 'when none are found' do
      before do
        allow(Honeybadger).to receive(:notify)
      end

      let(:tags) { ['LAB : MAPS'] }

      it 'returns default value' do
        expect(goobi_workflow_name).to eq(Settings.goobi.default_goobi_workflow_name)
        expect(Honeybadger).to have_received(:notify).once.with(
          '[DATA ERROR] Unexpected Goobi workflow name',
          context: {
            druid:,
            tags:
          }
        )
      end
    end
  end

  describe '#goobi_tag_list' do
    let(:goobi_tag_list) { goobi.send(:goobi_tag_list) }

    it 'returns an array of arrays with the tags from the object in the key:value format expected by goobi' do
      allow(AdministrativeTags).to receive(:for)
        .and_return(['DPG : Workflow : book_workflow',
                     'LAB : Map Work'])
      expect(goobi_tag_list.length).to eq 2
      goobi_tag_list.each { |goobi_tag| expect(goobi_tag.class).to eq Dor::GoobiTag }
      expect(goobi_tag_list[0]).to have_attributes(name: 'DPG', value: 'Workflow : book_workflow')
      expect(goobi_tag_list[1]).to have_attributes(name: 'LAB', value: 'Map Work')
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
      allow(AdministrativeTags).to receive(:for).and_return(['DPG : Workflow : book_workflow',
                                                             'LAB : MAPS'])
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
      allow(goobi).to receive_messages(goobi_workflow_name: 'goobi_workflow', collection_id: 'druid:oo000oo0001',
                                       collection_name: 'collection name', project_name: 'Project Name')
      allow(AdministrativeTags).to receive(:for).and_return(tags)
    end

    context 'when folio enabled' do
      context 'without ocr tag present' do
        let(:tags) { ['DPG : Workflow : book_workflow & stuff', 'LAB : MAPS'] }

        it 'creates the correct xml request with folio instance hrid' do
          expect(xml_request).to be_equivalent_to <<-XML
            <stanfordCreationRequest>
              <objectId>#{druid}</objectId>
              <objectType>item</objectType>
              <sourceID>some:source_id</sourceID>
              <title>Object Title &amp; A Special character</title>
              <contentType>Book (ltr)</contentType>
              <project>Project Name</project>
              <catkey>a11403803</catkey>
              <barcode>#{barcode}</barcode>
              <collectionId>druid:oo000oo0001</collectionId>
              <collectionName>collection name</collectionName>
              <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
              <goobiWorkflow>goobi_workflow</goobiWorkflow>
              <ocr>false</ocr>
              <tags>
                  <tag name="DPG" value="Workflow : book_workflow &amp; stuff"/>
                  <tag name="LAB" value="MAPS"/>
              </tags>
            </stanfordCreationRequest>
          XML
        end
      end

      context 'with ocr tag present' do
        let(:tags) { ['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'] }

        it 'creates the correct xml request' do
          expect(xml_request).to be_equivalent_to <<-XML
            <stanfordCreationRequest>
              <objectId>#{druid}</objectId>
              <objectType>item</objectType>
              <sourceID>some:source_id</sourceID>
              <title>Object Title &amp; A Special character</title>
              <contentType>Book (ltr)</contentType>
              <project>Project Name</project>
              <catkey>a11403803</catkey>
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
          XML
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
            purl: Purl.for(druid:)
          }
        end

        it 'creates the correct xml request when MODs title exists with a special character' do
          expect(xml_request).to be_equivalent_to <<-XML
            <stanfordCreationRequest>
              <objectId>#{druid}</objectId>
              <objectType>item</objectType>
              <sourceID>some:source_id</sourceID>
              <title>Constituent label &amp; A Special character</title>
              <contentType>Book (ltr)</contentType>
              <project>Project Name</project>
              <catkey>a11403803</catkey>
              <barcode>#{barcode}</barcode>
              <collectionId>druid:oo000oo0001</collectionId>
              <collectionName>collection name</collectionName>
              <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
              <goobiWorkflow>goobi_workflow</goobiWorkflow>
              <ocr>false</ocr>
              <tags></tags>
            </stanfordCreationRequest>
          XML
        end
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
        expect(response.status).to eq 201 # rubocop:disable RSpecRails/HaveHttpStatus
      end
    end

    context 'with a 409 response' do
      before do
        allow(Faraday).to receive(:post).and_call_original
        stub_request(:post, Settings.goobi.url)
          .to_return(body: '<somexml/>', headers: { 'Content-Type' => 'text/xml' }, status: 409)
      end

      it 'makes a call to the goobi server with the appropriate xml params' do
        expect(response.status).to eq 409 # rubocop:disable RSpecRails/HaveHttpStatus
        expect(Faraday).to have_received(:post).once # Don't retry request errors
      end
    end
  end

  describe '#content_type' do
    subject(:content_type) { goobi.send :content_type }

    it 'returns the type from cocina' do
      expect(content_type).to eq 'Book (ltr)'
    end
  end

  describe '#project_name' do
    subject(:project_name) { goobi.send :project_name }

    it 'returns project name from a valid identityMetadata' do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : Batchelor Maps : Batch 1',
                                                             'LAB : MAPS'])
      expect(project_name).to eq('Batchelor Maps : Batch 1')
    end

    it 'returns blank for project name if not in tag' do
      allow(AdministrativeTags).to receive(:for).and_return(['LAB : MAPS'])
      expect(project_name).to eq('')
    end
  end
end
