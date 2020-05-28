# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ServiceItem do
  subject(:si) { Dor::ServiceItem.new dor_item }

  let(:dor_item) { @dor_item }

  describe '#catkey' do
    context 'when catkey exists' do
      let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111', catkey: '8832162') }

      it 'returns catkey from a valid identityMetadata' do
        expect(si.ckey).to eq('8832162')
        expect(si.previous_ckeys).to eq([])
      end
    end

    context 'when previous_catkeys exists' do
      let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111') }

      before do
        dor_item.identityMetadata.add_other_Id('previous_catkey', '123')
      end

      it 'returns nil for current catkey but values for previous catkeys in identityMetadata' do
        expect(si.ckey).to be_nil
        expect(si.previous_ckeys).to eq(%w(123))
      end
    end

    context 'when previous_catkeys and catkey are empty' do
      let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111') }

      it 'returns nil for current catkey and empty array for previous catkeys in identityMetadata without either' do
        expect(si.ckey).to be_nil
        expect(si.previous_ckeys).to eq([])
      end
    end
  end

  describe '#goobi_workflow_name' do
    before do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
    end

    it 'returns goobi_workflow_name from a valid identityMetadata' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(si.goobi_workflow_name).to eq('book_workflow')
    end

    it 'returns first goobi_workflow_name if multiple are in the tags' do
      allow(AdministrativeTags).to receive(:for)
        .with(pid: @dor_item.id)
        .and_return(['DPG : Workflow : book_workflow', 'DPG : Workflow : another_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(si.goobi_workflow_name).to eq('book_workflow')
    end

    it 'returns blank for goobi_workflow_name if none are found' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['Process : Content Type : Book (flipbook, ltr)'])
      expect(si.goobi_workflow_name).to eq(Settings.goobi.default_goobi_workflow_name)
    end
  end

  describe '#goobi_tag_list' do
    before do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
    end

    it 'returns an array of arrays with the tags from the object in the key:value format expected to be passed to goobi' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)', 'LAB : Map Work'])
      expect(si.goobi_tag_list.length).to eq 3
      si.goobi_tag_list.each { |goobi_tag| expect(goobi_tag.class).to eq Dor::GoobiTag }
      expect(si.goobi_tag_list[0]).to have_attributes(name: 'DPG', value: 'Workflow : book_workflow')
      expect(si.goobi_tag_list[1]).to have_attributes(name: 'Process', value: 'Content Type : Book (flipbook, ltr)')
      expect(si.goobi_tag_list[2]).to have_attributes(name: 'LAB', value: 'Map Work')
    end

    it 'returns an empty array when there are no tags' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return([])
      expect(si.goobi_tag_list).to eq([])
    end

    it 'works with singleton tags (no colon, so no value, just a name)' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['Name : Some Value', 'JustName'])
      expect(si.goobi_tag_list.length).to eq 2
      expect(si.goobi_tag_list[0].class).to eq Dor::GoobiTag
      expect(si.goobi_tag_list[0]).to have_attributes(name: 'Name', value: 'Some Value')
      expect(si.goobi_tag_list[1]).to have_attributes(name: 'JustName', value: nil)
    end
  end

  describe '#goobi_ocr_tag_present?' do
    before do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
    end

    it 'returns false if the goobi ocr tag is not present' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(si.goobi_ocr_tag_present?).to be false
    end

    it 'returns true if the goobi ocr tag is present' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['DPG : Workflow : book_workflow', 'DPG : OCR : TRUE'])
      expect(si.goobi_ocr_tag_present?).to be true
    end

    it 'returns true if the goobi ocr tag is present even if the case is mixed' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['DPG : Workflow : book_workflow', 'DPG : ocr : true'])
      expect(si.goobi_ocr_tag_present?).to be true
    end
  end

  describe '#object_type' do
    context 'with object_type' do
      let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111', object_type: 'item') }

      it 'returns object_type from a valid identityMetadata' do
        expect(si.object_type).to eq('item')
      end
    end

    context 'without object_type' do
      let(:dor_item) { Dor::Abstract.new(pid: 'druid:aa111aa1111') }

      it 'returns a blank object type for identityMetadata without object_type' do
        expect(si.object_type).to be_nil
      end
    end
  end

  describe '#project_name' do
    before do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
    end

    it 'returns project name from a valid identityMetadata' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['Project : Batchelor Maps : Batch 1', 'Process : Content Type : Book (flipbook, ltr)'])
      expect(si.project_name).to eq('Batchelor Maps : Batch 1')
    end

    it 'returns blank for project name if not in tag' do
      allow(AdministrativeTags).to receive(:for).with(pid: @dor_item.id).and_return(['Process : Content Type : Book (flipbook, ltr)'])
      expect(si.project_name).to eq('')
    end
  end

  describe '#collection_name and id' do
    before do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
    end

    it 'returns collection name and id from a valid identityMetadata' do
      collection = Dor::Collection.new(pid: 'druid:cc111cc1111')
      allow(collection).to receive_messages(label: 'Collection label', id: 'druid:cc111cc1111')
      allow(@dor_item).to receive(:collections).and_return([collection])
      expect(si.collection_name).to eq('Collection label')
      expect(si.collection_id).to eq('druid:cc111cc1111')
    end

    it 'returns blank for collection name and id if there are none' do
      allow(@dor_item).to receive(:collections).and_return([])
      expect(si.collection_name).to eq('')
      expect(si.collection_id).to eq('')
    end
  end

  describe '#barcode' do
    let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111') }

    context 'when present' do
      before do
        dor_item.identityMetadata.add_other_Id('barcode', '36105216275185')
      end

      it 'returns barcode from a valid identityMetadata' do
        expect(si.barcode).to eq('36105216275185')
      end
    end

    it 'returns an empty string without barcode' do
      expect(si.barcode).to be_nil
    end
  end

  describe '#content_type' do
    let(:druid) { 'bb111bb2222' }
    let(:item) { Dor::Item.new(pid: druid) }

    before do
      # We swap these two lines after https://github.com/sul-dlss/dor-services/pull/706
      # item.contentMetadata.contentType = ['map']
      item.contentMetadata.content = '<contentMetadata type="map" />'
    end

    it 'returns the content_type_tag from tag service if the value exists' do
      allow(AdministrativeTags).to receive(:content_type).and_return(['Process Value'])
      expect(Dor::ServiceItem.new(item).content_type).to eq('Process Value')
    end

    it 'returns the type from contentMetadata if content_type from tag service does not have a value' do
      allow(AdministrativeTags).to receive(:content_type).and_return([])
      expect(Dor::ServiceItem.new(item).content_type).to eq('map')
    end
  end

  describe '#thumb' do
    it 'returns thumb from a valid contentMetadata' do
      druid = 'bb111bb2222'
      d = Dor::Item.new(pid: druid)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      content_metadata_ds = double(Dor::ContentMetadataDS)
      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      rights_metadata_ds = double(Dor::RightsMetadataDS)
      allow(rights_metadata_ds).to receive(:dra_object).and_return(Dor::RightsAuth.parse(rights_metadata_ng_xml, true))

      allow(d).to receive(:datastreams).and_return('rightsMetadata' => rights_metadata_ds, 'contentMetadata' => content_metadata_ds)
      allow(content_metadata_ds).to receive(:ng_xml).and_return(content_metadata_ng_xml)

      expect(Dor::ServiceItem.new(d).thumb).to eq('bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'returns nil for contentMetadata without thumb' do
      druid = 'aa111aa2222'
      d = Dor::Item.new(pid: druid)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_2)
      content_metadata_ds = double(Dor::ContentMetadataDS)
      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      rights_metadata_ds = double(Dor::RightsMetadataDS)
      allow(rights_metadata_ds).to receive(:dra_object).and_return(Dor::RightsAuth.parse(rights_metadata_ng_xml, true))

      allow(d).to receive(:datastreams).exactly(4).times.and_return('rightsMetadata' => rights_metadata_ds, 'contentMetadata' => content_metadata_ds)
      allow(content_metadata_ds).to receive(:ng_xml).and_return(content_metadata_ng_xml)

      expect(Dor::ServiceItem.new(d).thumb).to be_nil
    end
  end
end
