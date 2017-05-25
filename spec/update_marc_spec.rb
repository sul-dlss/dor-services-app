require 'rails_helper'

RSpec.describe Dor::UpdateMarcRecordService do
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
      expect(@umrs).not_to receive(:push_symphony_records)
      @umrs.update
    end
  end

  context 'for a druid with a catkey' do
    it 'executes the UpdateMarcRecordService push_symphony_records method' do
      druid = 'druid:bb333dd4444'
      setup_test_objects(druid, build_identity_metadata_with_ckey)
      expect(@umrs).to receive(:ckey).exactly(4).times.and_return('8832162')
      expect(@umrs.generate_symphony_records).to eq(["8832162\t#{druid.gsub('druid:', '')}\t"])
      expect(@umrs).to receive(:push_symphony_records)
      @umrs.update
    end
  end

  describe '.push_symphony_records' do
    it 'should call the relevant methods' do
      setup_test_objects('druid:aa111aa1111', '')
      expect(@umrs).to receive(:generate_symphony_records).once
      expect(@umrs).to receive(:write_symphony_records).once
      @umrs.push_symphony_records
    end
  end

  describe '.generate_symphony_records' do
    let(:item) { Dor::Item.new }
    let(:collection) { Dor::Collection.new }
    let(:constituent) { Dor::Item.new }

    let(:rels_ext_xml) { double(String) }
    let(:identity_metadata_xml) { double(String) }
    let(:content_metadata_xml) { double(String) }
    let(:desc_metadata_xml) { double(String) }
    let(:rights_metadata_xml) { double(String) }
    let(:release_data) { { 'Searchworks' => { 'release' => true } } }

    before :each do
      allow(item).to receive(:released_for).and_return(release_data)
      allow(collection).to receive(:released_for).and_return(release_data)
    end

    it 'should generate an empty array for a druid object without catkey or previous catkeys' do
      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_4)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111',
        catkey: '12345678'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'identityMetadata' => identity_metadata_xml, 'rightsMetadata' => rights_metadata_xml }
      )

      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_records).to eq([])
    end

    it 'should generate a single symphony record for an item object with a catkey' do
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

      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'rightsMetadata' => rights_metadata_xml, 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml, 'RELS-EXT' => rels_ext_xml }
      )

      allow(constituent).to receive_messages(
        id: 'dd111dd1111',
        datastreams: { 'descMetadata' => desc_metadata_xml }
      )

      allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
      updater = Dor::UpdateMarcRecordService.new(item)
      # rubocop:disable Metrics/LineLength
      expect(updater.generate_symphony_records).to eq(["8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label"])
      # rubocop:enble Metrics/LineLength
    end

    it 'should generate symphony record with a z subfield for a stanford only item object with catkey' do
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

      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_2)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'rightsMetadata' => rights_metadata_xml, 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml, 'RELS-EXT' => rels_ext_xml }
      )

      allow(constituent).to receive_messages(
        id: 'dd111dd1111',
        datastreams: { 'descMetadata' => desc_metadata_xml }
      )

      allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_records).to match_array(["8832162\taa111aa1111\t.856. 41|zAvailable to Stanford-affiliated users.|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label"])
    end

    it 'should generate blank symphony records and a regular symphony record for an item object with both previous and current catkeys' do
      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_3)
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

      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'rightsMetadata' => rights_metadata_xml, 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml, 'RELS-EXT' => rels_ext_xml }
      )

      allow(constituent).to receive_messages(
        id: 'dd111dd1111',
        datastreams: { 'descMetadata' => desc_metadata_xml }
      )

      allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_records).to match_array(["123\taa111aa1111\t", "456\taa111aa1111\t", "8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label"])
    end

    it 'should generate blank symphony records for an item object with only previous catkeys' do
      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_5)
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

      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'rightsMetadata' => rights_metadata_xml, 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml, 'RELS-EXT' => rels_ext_xml }
      )

      allow(constituent).to receive_messages(
        id: 'dd111dd1111',
        datastreams: { 'descMetadata' => desc_metadata_xml }
      )

      allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_records).to match_array(%W(123\taa111aa1111\t 456\taa111aa1111\t))
    end

    it 'should generate a single symphony record for a collection object with a catkey' do
      rights_metadata_ng_xml = Nokogiri::XML(build_rights_metadata_1)
      allow(rights_metadata_xml).to receive_messages(
        ng_xml: rights_metadata_ng_xml,
        dra_object: Dor::RightsAuth.parse(rights_metadata_ng_xml, true)
      )

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_2)
      )

      allow(identity_metadata_xml).to receive(:tag).and_return('Project : Batchelor Maps : Batch 1')
      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'aa111aa1111',
        collections: [],
        datastreams: { 'rightsMetadata' => rights_metadata_xml, 'identityMetadata' => identity_metadata_xml }
      )

      updater = Dor::UpdateMarcRecordService.new(collection)
      expect(updater.generate_symphony_records).to match_array(["8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xcollection"])
    end
  end

  describe '.write_symphony_records' do
    before :each do
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr_purl"
      Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
      @output_file = "#{@fixtures}/sdr_purl/sdr-purl-856s"
      setup_test_objects('druid:aa111aa1111', '')
      @updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(File.exist?(@output_file)).to be_falsey
    end
    after :each do
      FileUtils.rm_f(@output_file)
    end

    subject(:writer) { @updater.write_symphony_records marc_records }

    context 'for a single record' do
      let(:marc_records) { ['abcdef'] }
      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File.exist?(@output_file)).to be_truthy
        expect(File.read(@output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'for multiple records including special characters' do
      let(:marc_records) { %w(ab!#cdef 12@345 thirdrecord'withquote fourthrecordwith"doublequote) }
      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File.exist?(@output_file)).to be_truthy
        expect(File.read(@output_file)).to eq "#{marc_records[0]}\n#{marc_records[1]}\n#{marc_records[2]}\n#{marc_records[3]}\n"
      end
    end

    context 'for an empty array' do
      let(:marc_records) { [] }
      it 'does nothing' do
        expect(writer).to be_nil
        expect(File.exist?(@output_file)).to be_falsey
      end
    end

    context 'for nil' do
      let(:marc_records) { nil }
      it 'does nothing' do
        expect(writer).to be_nil
        expect(File.exist?(@output_file)).to be_falsey
      end
    end

    context 'for a record with single quotes' do
      let(:marc_records) { ["this is | a record | that has 'single quotes' in it | and it should work"] }
      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File.exist?(@output_file)).to be_truthy
        expect(File.read(@output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'for a record with double and single quotes' do
      let(:marc_records) { ['record with "double quotes" in it | and it should work'] }
      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File.exist?(@output_file)).to be_truthy
        expect(File.read(@output_file)).to eq "#{marc_records.first}\n"
      end
    end
  end

  describe '.get_z_field' do
    it 'should return a blank z message' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_1)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('')
    end
    it 'should return a non-blank z message for a stanford only object' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_2)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
    end
    it 'should return a non-blank z message for a location restricted object' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_3)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
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
    it 'should return 1 for a non born digital APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('info:fedora/druid:mb062dy1188')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('1')
    end
    it 'should return 0 for an ETDs APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('druid:bx911tp9024')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('0')
    end
    it 'should return 0 for an EEMs APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('druid:jj305hm5259')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('0')
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
      rights_metadata = double(Dor::RightsMetadataDS)
      expect(c).to receive(:remove_druid_prefix).and_return('')
      expect(c).to receive(:collections).and_return([])
      allow(c).to receive(:rightsMetadata).and_return(rights_metadata)
      allow(rights_metadata).to receive(:dra_object).and_return(double(Dor::RightsAuth))
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
      expect(@umrs.released_to_searchworks?).to be true
    end
    it 'should return true if release_data tag has release to=searchworks (all lowercase) and value is true' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'searchworks' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be true
    end
    it 'should return true if release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'SearchWorks' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be true
    end
    it 'should return false if release_data tag has release to=Searchworks and value is false' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = { 'Searchworks' => { 'release' => false } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be false
    end
    it 'should return false if release_data tag has release to=Searchworks but no specified release value' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = { 'Searchworks' => { 'bogus' => 'yup' } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be false
    end
    it 'should return false if there are no release tags at all' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
      release_data = {}
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be false
    end
    it 'should return false if there are non searchworks related release tags' do
      setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
      release_data = { 'Revs' => { 'release' => true } }
      allow(@dor_item).to receive(:released_for).and_return(release_data)
      expect(@umrs.released_to_searchworks?).to be false
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
