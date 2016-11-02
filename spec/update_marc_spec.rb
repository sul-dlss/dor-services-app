require 'spec_helper'

describe Dor::UpdateMarcRecordService do
  before :all do
    Dor::Config.suri = {}
    Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
    Dor::Config.release.symphony_path = './spec/fixtures/sdr-purl'
    Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
    @fixtures = './spec/fixtures'
  end

  context 'for a druid without a catkey' do
    it 'does nothing' do
      druid = 'druid:aa222cc3333'
      setup_test_objects(druid, build_identity_metadata_without_ckey)
      expect(@umrs).to receive(:ckey).and_return(nil)
      expect(@umrs).not_to receive(:push_symphony_record)
      @umrs.update
    end
  end

  context 'for a druid with a catkey' do
    it 'executes the UpdateMarcRecordService push_symphony_record method' do
      druid = 'druid:bb333dd4444'
      setup_test_objects(druid, build_identity_metadata_with_ckey)
      expect(@umrs).to receive(:ckey).exactly(3).times.and_return('8832162')
      expect(@umrs.generate_symphony_record).to eq("8832162\t#{druid.gsub('druid:', '')}\t")
      expect(@umrs).to receive(:push_symphony_record)
      @umrs.update
    end
  end

  describe '.push_symphony_record' do
    it 'should call the relevant methods' do
      setup_test_objects('druid:aa111aa1111', '')
      expect(@umrs).to receive(:generate_symphony_record).once
      expect(@umrs).to receive(:write_symphony_record).once
      @umrs.push_symphony_record
    end
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
      # rubocop:disable Metrics/LineLength
      expect(updater.generate_symphony_record).to eq("8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label")
      # rubocop:enble Metrics/LineLength
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
    before :each do
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr_purl"
      Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
      @output_file = "#{@fixtures}/sdr_purl/sdr-purl-856s"
      setup_test_objects('druid:aa111aa1111', '')
      @updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(File.exist?(@output_file)).to be_falsey
    end

    it 'should write the symphony record to the symphony directory' do
      marc_record = 'abcdef'
      @updater.write_symphony_record marc_record
      expect(File.exist?(@output_file)).to be_truthy
      expect(File.read(@output_file)).to eq "#{marc_record}\n"
    end

    it 'should do nothing if the symphony record is empty' do
      @updater.write_symphony_record ''
      expect(File.exist?(@output_file)).to be_falsey
    end

    it 'should do nothing if the symphony record is nil' do
      @updater.write_symphony_record nil
      expect(File.exist?(@output_file)).to be_falsey
    end

    after :each do
      FileUtils.rm_f(@output_file)
    end
  end

  describe '.get_856_cons' do
    it 'should return a valid sdrpurl constant' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    it 'should return 4' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    it 'should return 1' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('1')
    end
  end

  describe '.get_u_field' do
    it 'should return valid purl url' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
      expect(updater.get_u_field).to eq('|uhttp://purl.stanford.edu/aa111aa1111')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    it 'should return a valid sdrpurl constant' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    it 'should return an empty string for an object without collection' do
      setup_test_objects('druid:aa111aa1111', '')
      expect(@dor_item).to receive(:collections).and_return([])
      expect(@umrs.get_x2_collection_info).to be_empty
    end

    it 'should return an empty string for a collection object' do
      c = double(Dor::Collection)
      expect(c).to receive(:remove_druid_prefix).and_return('')
      expect(c).to receive(:collections).and_return([])
      updater = Dor::UpdateMarcRecordService.new(c)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'should return the appropriate information for a collection object' do
      setup_test_objects('druid:aa111aa1111', '')
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
      allow(@dor_item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection]
      )
      expect(@umrs.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label')
    end
  end

  describe 'Released to Searchworks' do
    it 'should return true if release_data tag has release to=Searchworks and value is true' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'Searchworks' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be true
    end
    it 'should return true if release_data tag has release to=searchworks (all lowercase) and value is true' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'searchworks' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be true
    end
    it 'should return true if release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'SearchWorks' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be true
    end
    it 'should return false if release_data tag has release to=Searchworks and value is false' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = { 'Searchworks' => { 'release' => false } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be false
    end
    it 'should return false if release_data tag has release to=Searchworks but no specified release value' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = { 'Searchworks' => { 'bogus' => 'yup' } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be false
    end
    it 'should return false if there are no release tags at all' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = {}
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be false
    end
    it 'should return false if there are non searchworks related release tags' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'Revs' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks).to be false
    end
  end

  describe 'dor_items_for_constituents' do
    it 'should return empty array if no relationships' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:relationships).and_return(nil)
      expect(Dor::UpdateMarcRecordService.new(@dor_item).send(:dor_items_for_constituents)).to eq([])
    end
    it 'successfully determines constituent druid' do
      setup_test_objects('druid:mb062dy1188', '')
      allow(@dor_item).to receive(:relationships).and_return(['info:fedora/druid:mb062dy1188'])
      expect(Dor::Item).to receive(:find).with('druid:mb062dy1188')
      Dor::UpdateMarcRecordService.new(@dor_item).send(:dor_items_for_constituents)
    end
  end
end
