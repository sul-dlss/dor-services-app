require 'rails_helper'

RSpec.describe Dor::ServiceItem do
  describe '.catkey' do
    it 'should return catkey from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).times.and_return('identityMetadata' => identity_metadata_ds)
      allow(@dor_item).to receive(:identityMetadata).and_return(identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.ckey).to eq('8832162')
    end

    it 'should return nil for an identityMetadata without catkey' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).times.and_return('identityMetadata' => identity_metadata_ds)
      allow(@dor_item).to receive(:identityMetadata).and_return(identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.ckey).to be_nil
    end
  end

  describe '.goobi_workflow_name' do
    it 'should return goobi_workflow_name from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:tags).and_return(['DPG : Workflow : book_workflow', 'Process : Content Type : Book (flipbook, ltr)'])

      expect(@si.goobi_workflow_name).to eq('book_workflow')
    end
    it 'should return first goobi_workflow_name if multiple are in the tags' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:tags).and_return(['DPG : Workflow : book_workflow', 'DPG : Workflow : another_workflow', 'Process : Content Type : Book (flipbook, ltr)'])

      expect(@si.goobi_workflow_name).to eq('book_workflow')
    end
    it 'should return blank for goobi_workflow_name if none are found' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:tags).and_return(['Process : Content Type : Book (flipbook, ltr)'])

      expect(@si.goobi_workflow_name).to eq(Dor::Config.goobi.default_goobi_workflow_name)
    end
  end

  describe '.object_type' do
    it 'should return object_type from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.object_type).to eq('item')
    end

    it 'should return a blank object type for identityMetadata without object_type' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.object_type).to be_nil
    end
  end

  describe '.project_name' do
    it 'should return project name from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:tags).and_return(['Project : Batchelor Maps : Batch 1', 'Process : Content Type : Book (flipbook, ltr)'])

      expect(@si.project_name).to eq('Batchelor Maps : Batch 1')
    end

    it 'should return blank for project name if not in tag' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:tags).and_return(['Process : Content Type : Book (flipbook, ltr)'])

      expect(@si.project_name).to eq('')
    end
  end

  describe '.collection_name and id' do
    it 'should return collection name and id from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      collection = Dor::Collection.new(:pid => 'druid:cc111cc1111')
      allow(collection).to receive_messages(label: 'Collection label', id: 'druid:cc111cc1111')
      allow(@dor_item).to receive(:collections).and_return([collection])

      expect(@si.collection_name).to eq('Collection label')
      expect(@si.collection_id).to eq('druid:cc111cc1111')
    end

    it 'should return blank for collection name and id if there are none' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)
      allow(@dor_item).to receive(:collections).and_return([])

      expect(@si.collection_name).to eq('')
      expect(@si.collection_id).to eq('')
    end
  end

  describe '.barcode' do
    it 'should return barcode from a valid identityMetadata' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.barcode).to eq('36105216275185')
    end

    it 'should return an empty string without barcode' do
      setup_test_objects('druid:aa111aa1111', '')
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      allow(@dor_item).to receive(:datastreams).and_return('identityMetadata' => identity_metadata_ds)
      allow(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      expect(@si.barcode).to be_nil
    end
  end

  describe '.content_type' do
    before :each do
      druid = 'bb111bb2222'
      @d = Dor::Item.new(:pid => druid)
      @content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      @content_metadata_ds = double(Dor::ContentMetadataDS)
      @identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      @identity_metadata_ds = double(Dor::IdentityMetadataDS)
      allow(@d).to receive(:datastreams).and_return('contentMetadata' => @content_metadata_ds, 'identityMetadata' => @identity_metadata_ds)
      allow(@content_metadata_ds).to receive(:ng_xml).and_return(@content_metadata_ng_xml)
      allow(@identity_metadata_ds).to receive(:ng_xml).and_return(@identity_metadata_ng_xml)
    end

    it 'should return the content_type_tag from dor-services if the value exists' do
      fake_tags = ['Tag 1', 'Tag 2', 'Process : Content Type : Process Value']
      allow(@identity_metadata_ds).to receive_messages(:tags => fake_tags, :tag => fake_tags)
      expect(Dor::ServiceItem.new(@d).content_type).to eq('Process Value')
    end

    it 'should return the type from contentMetadata if content_type_tag from dor-services does not have a value' do
      fake_tags = ['Tag 1', 'Tag 2', 'Tag 3']
      allow(@identity_metadata_ds).to receive_messages(:tags => fake_tags, :tag => fake_tags)
      expect(Dor::ServiceItem.new(@d).content_type).to eq('map')
    end
  end

  describe '.thumb' do
    it 'should return thumb from a valid contentMetadata' do
      druid = 'bb111bb2222'
      d = Dor::Item.new(:pid => druid)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      allow(d).to receive(:datastreams).and_return('contentMetadata' => content_metadata_ds)
      allow(content_metadata_ds).to receive(:ng_xml).and_return(content_metadata_ng_xml)

      expect(Dor::ServiceItem.new(d).thumb).to eq('bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'should return an empty string for contentMetadata without thumb' do
      druid = 'aa111aa2222'
      d = Dor::Item.new(:pid => druid)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_3)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      allow(d).to receive(:datastreams).exactly(4).times.and_return('contentMetadata' => content_metadata_ds)
      allow(content_metadata_ds).to receive(:ng_xml).and_return(content_metadata_ng_xml)

      expect(Dor::ServiceItem.new(d).thumb).to be_nil
    end
  end
end
