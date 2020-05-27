# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ServiceItem do
  subject(:si) { Dor::ServiceItem.new dor_item }

  let(:dor_item) { @dor_item }

  describe '#catkey' do
    it 'returns catkey from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      expect(si.ckey).to eq('8832162')
      expect(si.previous_ckeys).to eq([])
    end

    it 'returns nil for current catkey but values for previous catkeys in identityMetadata' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_5)
      expect(si.ckey).to be_nil
      expect(si.previous_ckeys).to eq(%w(123 456))
    end

    it 'returns nil for current catkey and empty array for previous catkeys in identityMetadata without either' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_4)
      expect(si.ckey).to be_nil
      expect(si.previous_ckeys).to eq([])
    end
  end

  describe '#object_type' do
    it 'returns object_type from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      expect(si.object_type).to eq('item')
    end

    it 'returns a blank object type for identityMetadata without object_type' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_6)
      expect(si.object_type).to be_nil
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

  describe '#barcode' do
    it 'returns barcode from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      expect(si.barcode).to eq('36105216275185')
    end

    it 'returns an empty string without barcode' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_3)
      expect(si.barcode).to be_nil
    end
  end

  describe '#content_type' do
    let(:druid) { 'bb111bb2222' }
    let(:item) { Dor::Item.new(pid: druid) }

    before do
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      content_metadata_ds = double(Dor::ContentMetadataDS)
      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      rights_metadata_ds = double(Dor::RightsMetadataDS)
      allow(item).to receive(:datastreams).and_return('rightsMetadata' => rights_metadata_ds,
                                                      'contentMetadata' => content_metadata_ds)
      allow(content_metadata_ds).to receive(:ng_xml).and_return(content_metadata_ng_xml)
      allow(rights_metadata_ds).to receive(:ng_xml).and_return(rights_metadata_ng_xml)
      allow(rights_metadata_ds).to receive(:dra_object).and_return(
        Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )
    end

    it 'returns the content_type_tag from dor-services if the value exists' do
      allow(AdministrativeTags).to receive(:content_type).and_return(['Process Value'])
      expect(Dor::ServiceItem.new(item).content_type).to eq('Process Value')
    end

    it 'returns the type from contentMetadata if content_type_tag from dor-services does not have a value' do
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
