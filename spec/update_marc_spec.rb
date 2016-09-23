require 'spec_helper'

describe Dor::UpdateMarcRecordService do
  
  before :all do
    Dor::Config.suri = {}
    Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
    Dor::Config.release.symphony_path = './spec/fixtures/sdr-purl'
    Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
    @fixtures = './spec/fixtures'
  end

  context "for a druid without a catkey" do
    it 'does nothing' do
      druid='druid:aa222cc3333'
      setup_marc_record(druid,build_identity_metadata_without_ckey)
      expect(@umrs).to receive(:ckey).with(@dor_item).and_return(nil)
      expect(@umrs).not_to receive(:push_symphony_record)
      @umrs.update
    end
  end

  context "for a druid with a catkey" do
    it "executes the UpdateMarcRecordService push_symphony_record method" do
      druid='druid:bb333dd4444'
      setup_marc_record(druid,build_identity_metadata_with_ckey)
      expect(@umrs).to receive(:ckey).twice.with(@dor_item).and_return('8832162')
      expect(@umrs.generate_symphony_record).to eq("8832162\t#{druid.gsub('druid:','')}\t")
      expect(@umrs).to receive(:push_symphony_record)
      @umrs.update
    end
  end
  
  describe '.push_symphony_record' do
    pending
  end

  describe '.generate_symphony_record' do
    
    it 'should generate an empty string for a druid object without catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
      
      item = Dor::Item.new
      collection = Dor::Collection.new
      identity_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_3)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111',
        catkey: '12345678'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'identityMetadata' => identity_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(item).to receive(:released_for).and_return(release_data)
      allow(collection).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_record).to eq('')
    end
    it 'should generate symphony record for a item object with catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'

      item = Dor::Item.new
      collection = Dor::Collection.new
      constituent = Dor::Item.new

      rels_ext_xml = double(String)
      identity_metadata_xml = double(String)
      content_metadata_xml = double(String)
      desc_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_1)
      )

      allow(content_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_content_metadata_1)
      )

      allow(desc_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_desc_metadata_1)
      )

      allow(rels_ext_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_rels_ext)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml, 'RELS-EXT' => rels_ext_xml }
      )

      allow(constituent).to receive_messages(
        id: 'dd111dd1111',
        datastreams: { 'descMetadata' => desc_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(item).to receive(:released_for).and_return(release_data)

      allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_record).to eq("8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label")
    end

    it 'should generate symphony record for a collection object with catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'

      collection = Dor::Collection.new
      identity_metadata_xml = double(String)
      content_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_2)
      )

      allow(identity_metadata_xml).to receive(:tag).and_return('Project : Batchelor Maps : Batch 1')
      allow(content_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_content_metadata_2)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'aa111aa1111',
        collections: [],
        datastreams: { 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(collection).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(collection)
      expect(updater.generate_symphony_record).to eq("8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xcollection|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2")
    end
  end

  describe '.write_symphony_record' do
    xit 'should write the symphony record to the symphony directory' do
      d = Dor::Item.new
      updater = Dor::UpdateMarcRecordService.new(d)
      updater.instance_variable_set(:@druid_id, 'aa111aa1111')
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
      updater.write_symphony_record 'aaa'

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be false
    end

    it 'should do nothing if the symphony record is empty' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      updater.write_symphony_record ''

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be true
    end

    it 'should do nothing if the symphony record is nil' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      updater.write_symphony_record ''

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be true
    end

    after :each do
      FileUtils.rm_rf("#{@fixtures}/sdr-purl/.")
    end
  end

  describe '.catkey' do
    it 'should return catkey from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).exactly(3).times.and_return({'identityMetadata' => identity_metadata_ds})
      expect(d).to receive(:identityMetadata).and_return(identity_metadata_ds)
      expect(identity_metadata_ds).to receive(:ng_xml).twice.and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.ckey(d)).to eq('8832162')
    end

    it 'should return nil for an identityMetadata without catkey' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).exactly(3).times.and_return({'identityMetadata' => identity_metadata_ds})
      expect(d).to receive(:identityMetadata).and_return(identity_metadata_ds)
      expect(identity_metadata_ds).to receive(:ng_xml).twice.and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.ckey(d)).to be_nil
    end
  end

  describe '.object_type' do
    it 'should return object_type from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.object_type).to eq('|xitem')
    end

    it 'should return an empty x subfield for identityMetadata without object_type' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.object_type).to eq('|x')
    end
  end

  describe '.barcode' do
    it 'should return barcode from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.barcode).to eq('|xbarcode:36105216275185')
    end

    it 'should return an empty x subfield for identityMetadata without barcode' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.barcode).to be nil
    end
  end

  describe '.file_id' do
    it 'should return file_id from a valid contentMetadata' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'should return an empty x subfield for contentMetadata without file_id' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_3)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('aa111aa2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq(nil)
    end

    it 'should return correct file_id from a valid contentMetadata  with resource type = image' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_4)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'should return correct file_id from a valid contentMetadata with resource type = page' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_5)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('aa111aa2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:aa111aa2222%2Fwt183gy6220_00_0002.jp2')
    end

    # Added thumb based upon recommendation from Lynn McRae for future use
    it 'should return correct file_id from a valid contentMetadata with resource type = thumb' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_6)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0002.jp2')
    end

    it 'should return correct file_id from a valid contentMetadata  with resource type = image' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_7)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('hj097bm8879')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:cg767mn6478%2F2542A.jp2')
    end
  end

  describe '.get_856_cons' do
    it 'should return a valid sdrpurl constant' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    it 'should return 4' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    it 'should return 1' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_2nd_indicator).to eq('1')
    end
  end

  describe '.get_u_field' do
    it 'should return valid purl url' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
      expect(updater.get_u_field).to eq('|uhttp://purl.stanford.edu/aa111aa1111')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    it 'should return a valid sdrpurl constant' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    it 'should return an empty string for an object without collection' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:collections).and_return([])
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'should return an empty string for a collection object' do
      c = double(Dor::Collection)
      expect(c).to receive(:id).and_return('')
      expect(c).to receive(:collections).and_return([])
      updater = Dor::UpdateMarcRecordService.new(c)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'should return the appropriate information for a collection object' do
      item = double(Dor::Item.new)
      collection = Dor::Collection.new
      identity_metadata_xml = String

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_2)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111',
        datastreams: { 'identityMetadata' => identity_metadata_xml }
      )
      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection]
      )
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label')
    end
  end

  describe 'Released to Searchworks' do
    it 'should return true if release_data tag has release to=Searchworks and value is true' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_1))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Searchworks' => { 'release' => true } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be true
    end
    it 'should return true if release_data tag has release to=searchworks (all lowercase) and value is true' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_1))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'searchworks' => { 'release' => true } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be true
    end
    it 'should return true if release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_1))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'SearchWorks' => { 'release' => true } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be true
    end
    it 'should return false if release_data tag has release to=Searchworks and value is false' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_2))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Searchworks' => { 'release' => false } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be false
    end
    it 'should return false if release_data tag has release to=Searchworks but no specified release value' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_2))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Searchworks' => { 'bogus' => 'yup' } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be false
    end   
    it 'should return false if there are no release tags at all' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_2))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = {}
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be false
    end    
    it 'should return false if there are non searchworks related release tags' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_2))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Revs' => { 'release' => true } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be false
    end      
  end

  describe 'dor_items_for_constituents' do
    it 'should return empty array if no relationships' do
      item = double('item', id: '12345', relationships: nil)
      expect(Dor::UpdateMarcRecordService.new(item).send(:dor_items_for_constituents)).to eq([])
    end
    it 'successfully determines constituent druid' do
      item = double('item', id: '12345', relationships: ['info:fedora/druid:mb062dy1188'])
      expect(Dor::Item).to receive(:find).with('druid:mb062dy1188')
      Dor::UpdateMarcRecordService.new(item).send(:dor_items_for_constituents)
    end
  end  
end


def build_identity_metadata_1
    '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="barcode">36105216275185</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15</tag>
  <release displayType="image" release="true" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">true</release>
</identityMetadata>'
end

def build_identity_metadata_2
      '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <objectType>collection</objectType>
    <displayType>image</displayType>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="catkey">8832162</otherId>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.15.4</tag>
    <release displayType="image" release="false" to="Searchworks" what="collection" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
    </identityMetadata>'
end

def build_identity_metadata_3
      '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_identity_metadata_4
      '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <objectType>item</objectType>
    <displayType>image</displayType>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="catkey">8832162</otherId>
    <otherId name="barcode">36105216275185</otherId>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.1</tag>
    <release displayType="image" release="false" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
  </identityMetadata>'
end

def build_release_data_1
      '<release_data>
  <release to="Searchworks">true</release>
  </release_data>'
end

def build_release_data_2
    '<release_data>
    <release to="Searchworks">false</release>
    </release_data>'
end

def build_content_metadata_1
  '<contentMetadata objectId="wt183gy6220" type="map">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>Image 1</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

def build_content_metadata_2
    '<contentMetadata objectId="wt183gy6220">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>Image 1</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_2" sequence="2" type="image">
  <label>Image 2</label>
  <file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

def build_content_metadata_3
    '<contentMetadata objectId="wt183gy6220">
    </contentMetadata>'
end

def build_content_metadata_4
      '<contentMetadata objectId="wt183gy6220">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>PDF 1</label>
  <file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_1" sequence="2" type="image">
  <label>Image 1</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_2" sequence="3" type="image">
  <label>Image 2</label>
  <file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

def build_content_metadata_5
      '<contentMetadata objectId="wt183gy6220">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>PDF 1</label>
  <file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_2" sequence="2" type="page">
  <label>Page 1</label>
  <file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_1" sequence="3" type="page">
  <label>Page 2</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

  # Added thumb based upon recommendation from Lynn McRae for future use
def build_content_metadata_6
      '<contentMetadata objectId="wt183gy6220">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>PDF 1</label>
  <file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_2" sequence="2" type="thumb">
  <label>Page 1</label>
  <file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  <resource id="wt183gy6220_1" sequence="3" type="page">
  <label>Page 2</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

def build_content_metadata_7
    '<contentMetadata objectId="hj097bm8879" type="image">
  <resource id="hj097bm8879_1" sequence="1" type="image">
  <label>Cover: Carey\'s American atlas.</label>
  <externalFile fileId="2542A.jp2" mimetype="image/jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1">
  <imageData width="6475" height="4747"/>
  </externalFile>
  <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_2" sequence="2" thumb="yes" type="image">
  <label>Title Page: Carey\'s American atlas.</label>
  <externalFile fileId="2542B.jp2" mimetype="image/jp2" objectId="druid:jw923xn5254" resourceId="jw923xn5254_1">
  <imageData width="3139" height="4675"/>
  </externalFile>
  <relationship objectId="druid:jw923xn5254" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_3" sequence="3" type="image">
  <label>British Possessions in North America.</label>
  <externalFile fileId="2542001.jp2" mimetype="image/jp2" objectId="druid:wn461xh4882" resourceId="wn461xh4882_1">
  <imageData width="6633" height="5305"/>
  </externalFile>
  <relationship objectId="druid:wn461xh4882" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_4" sequence="4" type="image">
  <label>Province of Maine.</label>
  <externalFile fileId="2542002.jp2" mimetype="image/jp2" objectId="druid:fh193nf4583" resourceId="fh193nf4583_1">
  <imageData width="4761" height="6117"/>
  </externalFile>
  <relationship objectId="druid:fh193nf4583" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_5" sequence="5" type="image">
  <label>State of New Hampshire.</label>
  <externalFile fileId="2542003.jp2" mimetype="image/jp2" objectId="druid:zm141bz6672" resourceId="zm141bz6672_1">
  <imageData width="4761" height="6721"/>
  </externalFile>
  <relationship objectId="druid:zm141bz6672" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_6" sequence="6" type="image">
  <label>Vermont.</label>
  <externalFile fileId="2542004.jp2" mimetype="image/jp2" objectId="druid:ty335fg4673" resourceId="ty335fg4673_1">
  <imageData width="4689" height="6065"/>
  </externalFile>
  <relationship objectId="druid:ty335fg4673" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_7" sequence="7" type="image">
  <label>State of Massachusetts.</label>
  <externalFile fileId="2542005.jp2" mimetype="image/jp2" objectId="druid:cb783jw9314" resourceId="cb783jw9314_1">
  <imageData width="7073" height="5553"/>
  </externalFile>
  <relationship objectId="druid:cb783jw9314" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_8" sequence="8" type="image">
  <label>Connecticut.</label>
  <externalFile fileId="2542006.jp2" mimetype="image/jp2" objectId="druid:yr145dc7638" resourceId="yr145dc7638_1">
  <imageData width="6161" height="4801"/>
  </externalFile>
  <relationship objectId="druid:yr145dc7638" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_9" sequence="9" type="image">
  <label>State of Rhode Island.</label>
  <externalFile fileId="2542007.jp2" mimetype="image/jp2" objectId="druid:qw237mm1478" resourceId="qw237mm1478_1">
  <imageData width="4657" height="6065"/>
  </externalFile>
  <relationship objectId="druid:qw237mm1478" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_10" sequence="10" type="image">
  <label>State of New York.</label>
  <externalFile fileId="2542008.jp2" mimetype="image/jp2" objectId="druid:bv599bt4452" resourceId="bv599bt4452_1">
  <imageData width="7577" height="5900"/>
  </externalFile>
  <relationship objectId="druid:bv599bt4452" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_11" sequence="11" type="image">
  <label>State of New Jersey.</label>
  <externalFile fileId="2542009.jp2" mimetype="image/jp2" objectId="druid:nb435pz3288" resourceId="nb435pz3288_1">
  <imageData width="4681" height="6817"/>
  </externalFile>
  <relationship objectId="druid:nb435pz3288" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_12" sequence="12" type="image">
  <label>State of Pennsylvania.</label>
  <externalFile fileId="2542010.jp2" mimetype="image/jp2" objectId="druid:sc006nj1332" resourceId="sc006nj1332_1">
  <imageData width="6805" height="4675"/>
  </externalFile>
  <relationship objectId="druid:sc006nj1332" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_13" sequence="13" type="image">
  <label>Delaware.</label>
  <externalFile fileId="2542011.jp2" mimetype="image/jp2" objectId="druid:mk475my0384" resourceId="mk475my0384_1">
  <imageData width="4737" height="6121"/>
  </externalFile>
  <relationship objectId="druid:mk475my0384" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_14" sequence="14" type="image">
  <label>State of Maryland.</label>
  <externalFile fileId="2542012.jp2" mimetype="image/jp2" objectId="druid:wp257mm9313" resourceId="wp257mm9313_1">
  <imageData width="6145" height="4741"/>
  </externalFile>
  <relationship objectId="druid:wp257mm9313" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_15" sequence="15" type="image">
  <label>State of Virginia.</label>
  <externalFile fileId="2542013.jp2" mimetype="image/jp2" objectId="druid:pw121jd8972" resourceId="pw121jd8972_1">
  <imageData width="7321" height="5251"/>
  </externalFile>
  <relationship objectId="druid:pw121jd8972" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_16" sequence="16" type="image">
  <label>State of North Carolina.</label>
  <externalFile fileId="2542014.jp2" mimetype="image/jp2" objectId="druid:dh865cc1881" resourceId="dh865cc1881_1">
  <imageData width="6793" height="4669"/>
  </externalFile>
  <relationship objectId="druid:dh865cc1881" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_17" sequence="17" type="image">
  <label>State of South Carolina.</label>
  <externalFile fileId="2542015.jp2" mimetype="image/jp2" objectId="druid:xt213gh5830" resourceId="xt213gh5830_1">
  <imageData width="7159" height="5890"/>
  </externalFile>
  <relationship objectId="druid:xt213gh5830" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_18" sequence="18" type="image">
  <label>Georgia.</label>
  <externalFile fileId="2542016.jp2" mimetype="image/jp2" objectId="druid:xw455fd1110" resourceId="xw455fd1110_1">
  <imageData width="6129" height="4729"/>
  </externalFile>
  <relationship objectId="druid:xw455fd1110" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_19" sequence="19" type="image">
  <label>Kentucky.</label>
  <externalFile fileId="2542017.jp2" mimetype="image/jp2" objectId="druid:pk237jz4413" resourceId="pk237jz4413_1">
  <imageData width="7553" height="4729"/>
  </externalFile>
  <relationship objectId="druid:pk237jz4413" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_20" sequence="20" type="image">
  <label>Map of The Tennassee (sic) Government.</label>
  <externalFile fileId="2542018.jp2" mimetype="image/jp2" objectId="druid:jp652gk0604" resourceId="jp652gk0604_1">
  <imageData width="7483" height="4657"/>
  </externalFile>
  <relationship objectId="druid:jp652gk0604" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_21" sequence="21" type="image">
  <label>South America.</label>
  <externalFile fileId="2542019.jp2" mimetype="image/jp2" objectId="druid:cs003qk0166" resourceId="cs003qk0166_1">
  <imageData width="6091" height="4693"/>
  </externalFile>
  <relationship objectId="druid:cs003qk0166" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_22" sequence="22" type="image">
  <label>
  Map of the Discoveries made by Capts. Cook & Clerk.
  </label>
  <externalFile fileId="2542020.jp2" mimetype="image/jp2" objectId="druid:th862dp3538" resourceId="th862dp3538_1">
  <imageData width="4615" height="3107"/>
  </externalFile>
  <relationship objectId="druid:th862dp3538" type="alsoAvailableAs"/>
  </resource>
  <resource id="hj097bm8879_23" sequence="23" type="image">
  <label>Chart of the West Indies.</label>
  <externalFile fileId="2542021.jp2" mimetype="image/jp2" objectId="druid:wq036fq6080" resourceId="wq036fq6080_1">
  <imageData width="6091" height="4699"/>
  </externalFile>
  <relationship objectId="druid:wq036fq6080" type="alsoAvailableAs"/>
  </resource>
  </contentMetadata>'
end

def build_rels_ext
    '<rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about="info:fedora/druid:cs003qk0166">
    <hydra:isGovernedBy rdf:resource="info:fedora/druid:sq161jk2248"/>
    <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"/>
    <fedora:isMemberOf rdf:resource="info:fedora/druid:xh235dd9059"/>
    <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"/>
    <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"/>
  </rdf:Description>
</rdf:RDF>'
end

def build_desc_metadata_1
    '<mods>
  <titleInfo>
    <title>Constituent label</title>
  </titleInfo></mods>'
end
  
def build_identity_metadata_with_ckey
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb333dd4444</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_identity_metadata_without_ckey
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:aa222cc3333</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end
