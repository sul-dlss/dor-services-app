# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::UpdateMarcRecordService do
  subject(:umrs) { Dor::UpdateMarcRecordService.new dor_item }

  let(:dor_item) { @dor_item }
  let(:release_service) { instance_double(ReleaseTags::IdentityMetadata, released_for: release_data) }
  let(:release_data) { {} }

  before do
    allow(ReleaseTags::IdentityMetadata).to receive(:for).and_return(release_service)
    Settings.release.symphony_path = './spec/fixtures/sdr-purl'
    Settings.release.purl_base_url = 'http://purl.stanford.edu'
    @fixtures = './spec/fixtures'
  end

  context 'for a druid without a catkey' do
    let(:build_identity_metadata_without_ckey) do
      <<~XML
        <identityMetadata>
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
        </identityMetadata>
      XML
    end

    let(:dor_item) { Dor::Item.new(pid: 'druid:aa222cc3333') }

    it 'does nothing' do
      expect(umrs).to receive(:ckey).and_return(nil)
      expect(umrs).not_to receive(:push_symphony_records)
      umrs.update
    end
  end

  context 'for a druid with a catkey' do
    let(:dor_item) { Dor::Item.new(pid: druid) }
    let(:druid) { 'druid:bb333dd4444' }

    it 'executes the UpdateMarcRecordService push_symphony_records method' do
      expect(umrs).to receive(:ckey).exactly(4).times.and_return('8832162')
      expect(umrs.generate_symphony_records).to eq(["8832162\t#{druid.gsub('druid:', '')}\t"])
      expect(umrs).to receive(:push_symphony_records)
      umrs.update
    end
  end

  describe '.push_symphony_records' do
    it 'calls the relevant methods' do
      setup_test_objects('druid:aa111aa1111', '')
      expect(umrs).to receive(:generate_symphony_records).once
      expect(umrs).to receive(:write_symphony_records).once
      umrs.push_symphony_records
    end
  end

  describe '.generate_symphony_records' do
    let(:item) { Dor::Item.new }
    let(:collection) { Dor::Collection.new }
    let(:constituent) { Dor::Item.new }
    let(:release_data) { { 'Searchworks' => { 'release' => true } } }

    context "when the druid object doesn't have catkey or previous catkeys" do
      it 'generates an empty array' do
        item.rightsMetadata.content = build_rights_metadata_1
        item.identityMetadata.content = build_identity_metadata_4

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'cc111cc1111',
          catkey: '12345678'
        )

        allow(item).to receive_messages(
          id: 'aa111aa1111',
          collections: [collection]
        )

        updater = Dor::UpdateMarcRecordService.new(item)
        expect(updater.generate_symphony_records).to eq([])
      end
    end

    context 'when an item object has a catkey' do
      it 'generates a single symphony record' do
        item.rightsMetadata.content = build_rights_metadata_1
        item.identityMetadata.content = build_identity_metadata_1
        item.contentMetadata.content = build_content_metadata_1

        constituent.descMetadata.content = build_desc_metadata_1

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'cc111cc1111'
        )

        allow(item).to receive_messages(
          pid: 'aa111aa1111',
          collections: [collection]
        )

        allow(constituent).to receive_messages(
          id: 'dd111dd1111'
        )

        allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
        updater = Dor::UpdateMarcRecordService.new(item)
        # rubocop:disable Metrics/LineLength
        expect(updater.generate_symphony_records).to eq(["8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label & A Special character"])
      end
    end

    context 'when an object is stanford only and has a catkey' do
      it 'generates symphony record with a z subfield' do
        item.rightsMetadata.content = build_rights_metadata_2
        item.identityMetadata.content = build_identity_metadata_1
        item.contentMetadata.content = build_content_metadata_1

        constituent.descMetadata.content = build_desc_metadata_1

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'cc111cc1111'
        )

        allow(item).to receive_messages(
          pid: 'aa111aa1111',
          collections: [collection]
        )

        allow(constituent).to receive_messages(
          id: 'dd111dd1111'
        )

        allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
        updater = Dor::UpdateMarcRecordService.new(item)
        expect(updater.generate_symphony_records).to match_array(["8832162\taa111aa1111\t.856. 41|zAvailable to Stanford-affiliated users.|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label & A Special character"])
      end
    end

    context 'when an object has both previous and current catkeys' do
      it 'generates blank symphony records and a regular symphony record' do
        item.rightsMetadata.content = build_rights_metadata_1
        item.identityMetadata.content = build_identity_metadata_3
        item.contentMetadata.content = build_content_metadata_1

        constituent.descMetadata.content = build_desc_metadata_1

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'cc111cc1111'
        )

        allow(item).to receive_messages(
          pid: 'aa111aa1111',
          collections: [collection]
        )

        allow(constituent).to receive_messages(
          id: 'dd111dd1111'
        )

        allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
        updater = Dor::UpdateMarcRecordService.new(item)
        expect(updater.generate_symphony_records).to match_array(["123\taa111aa1111\t", "456\taa111aa1111\t", "8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label|xset:dd111dd1111::Constituent label & A Special character"])
      end
    end

    context 'when an object has only previous catkeys' do
      it 'generates blank symphony records for an item object' do
        item.rightsMetadata.content = build_rights_metadata_1
        item.identityMetadata.content = build_identity_metadata_5
        item.contentMetadata.content = build_content_metadata_1

        constituent.descMetadata.content = build_desc_metadata_1

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'cc111cc1111'
        )

        allow(item).to receive_messages(
          id: 'aa111aa1111',
          collections: [collection]
        )

        allow(constituent).to receive_messages(
          id: 'dd111dd1111'
        )

        allow_any_instance_of(Dor::UpdateMarcRecordService).to receive(:dor_items_for_constituents).and_return([constituent])
        updater = Dor::UpdateMarcRecordService.new(item)
        expect(updater.generate_symphony_records).to match_array(%W(123\taa111aa1111\t 456\taa111aa1111\t))
      end
    end

    context 'when an collection object has a catkey' do
      it 'generates a single symphony record' do
        collection.rightsMetadata.content = build_rights_metadata_1
        collection.identityMetadata.content = build_identity_metadata_2

        allow(collection).to receive_messages(
          label: 'Collection label',
          id: 'aa111aa1111',
          collections: []
        )

        updater = Dor::UpdateMarcRecordService.new(collection)
        expect(updater.generate_symphony_records).to match_array(["8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xcollection"])
      end
    end
  end

  describe '.write_symphony_records' do
    subject(:writer) { @updater.write_symphony_records marc_records }

    before do
      Settings.release.symphony_path = "#{@fixtures}/sdr_purl"
      @output_file = "#{@fixtures}/sdr_purl/sdr-purl-856s"
      setup_test_objects('druid:aa111aa1111', '')
      @updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(File.exist?(@output_file)).to be_falsey
    end

    after do
      FileUtils.rm_f(@output_file)
    end

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
    it 'returns a blank z message' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_1)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('')
    end
    it 'returns a non-blank z message for a stanford only object' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_2)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
    end
    it 'returns a non-blank z message for a location restricted object' do
      setup_test_objects('druid:aa111aa1111', '', build_rights_metadata_3)
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
    end
  end

  describe '.get_856_cons' do
    it 'returns a valid sdrpurl constant' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    it 'returns 4' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    it 'returns 1 for a non born digital APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('info:fedora/druid:mb062dy1188')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('1')
    end
    it 'returns 0 for an ETDs APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('druid:bx911tp9024')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('0')
    end
    it 'returns 0 for an EEMs APO' do
      setup_test_objects('druid:aa111aa1111', '')
      allow(@dor_item).to receive(:admin_policy_object_id).and_return('druid:jj305hm5259')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_2nd_indicator).to eq('0')
    end
  end

  describe '.get_u_field' do
    it 'returns valid purl url' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      Settings.release.purl_base_url = 'http://purl.stanford.edu'
      expect(updater.get_u_field).to eq('|uhttp://purl.stanford.edu/aa111aa1111')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    it 'returns a valid sdrpurl constant' do
      setup_test_objects('druid:aa111aa1111', '')
      updater = Dor::UpdateMarcRecordService.new(@dor_item)
      expect(updater.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    it 'returns an empty string for an object without collection' do
      setup_test_objects('druid:aa111aa1111', '')
      expect(@dor_item).to receive(:collections).and_return([])
      expect(umrs.get_x2_collection_info).to be_empty
    end

    it 'returns an empty string for a collection object' do
      c = double(Dor::Collection, id: 'bb222bb2222')
      rights_metadata = double(Dor::RightsMetadataDS)
      expect(Dor::PidUtils).to receive(:remove_druid_prefix).and_return('')
      expect(c).to receive(:collections).and_return([])
      allow(c).to receive(:rightsMetadata).and_return(rights_metadata)
      allow(rights_metadata).to receive(:dra_object).and_return(double(Dor::RightsAuth))
      updater = Dor::UpdateMarcRecordService.new(c)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'returns the appropriate information for a collection object' do
      setup_test_objects('druid:aa111aa1111', '')
      collection = Dor::Collection.new
      collection.identityMetadata.content = build_identity_metadata_2

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )
      allow(@dor_item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection]
      )
      expect(umrs.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label')
    end
  end

  describe '#get_x2_part_info' do
    let(:dor_item) { Dor::Item.new(pid: 'druid:aa111aa1111') }

    before do
      dor_item.descMetadata.content = xml
    end

    context 'without descMetadata' do
      let(:xml) {}

      it 'returns nil for objects with part information' do
        expect(umrs.get_x2_part_info).to be_nil
      end
    end

    context 'with descMetadata without part information' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
          <title>Some label</title>
          </titleInfo></mods>
        XML
      end

      it 'returns an empty string for objects with part information' do
        expect(umrs.get_x2_part_info).to be_empty
      end
    end

    context 'with descMetadata with some part numbers' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
          <title>Some label</title>
          <partNumber>55th legislature</partNumber>
          <partNumber>1997-1998</partNumber>
          </titleInfo></mods>
        XML
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:55th legislature, 1997-1998'
      end
    end

    context 'with descMetadata with a part name and number' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
          <title>Some label</title>
          <partName>Issue #3</partName>
          <partNumber>2011</partNumber>
          </titleInfo></mods>
        XML
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with a sequential designation in a note' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
          <title>Some label</title>
          <partName>Issue #3</partName>
          <partNumber>2011</partNumber>
          </titleInfo>
          <note type="date/sequential designation">123</note>
          </mods>
        XML
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:123'
      end
    end

    context 'with descMetadata with a sequential designation on a part number' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
          <title>Some label</title>
          <partName>Issue #3</partName>
          <partNumber type="date/sequential designation">2011</partNumber>
          </titleInfo>
          </mods>
        XML
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:2011'
      end
    end

    context 'with descMetadata with multiple titles, one of them marked as the primary title' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo type="alternative" usage="garbage">
          <title>Some label</title>
          <partName>Some lie</partName>
          </titleInfo>
          <titleInfo type="alternative" usage="primary">
          <title>Some label</title>
          <partName>Issue #3</partName>
          <partNumber>2011</partNumber>
          </titleInfo>
          </mods>
        XML
      end

      it 'returns the label from the primary title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with multiple titles' do
      let(:xml) do
        <<-XML
          <mods xmlns="http://www.loc.gov/mods/v3">
          <titleInfo type="alternative">
          <title>Some label</title>
          <partName>Issue #3</partName>
          <partNumber>2011</partNumber>
          </titleInfo>
          <titleInfo type="alternative">
          <title>Some label</title>
          <partName>Some lie</partName>
          </titleInfo>
          </mods>
        XML
      end

      it 'returns the label from the first title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end
  end

  describe 'Released to Searchworks' do
    context 'when release_data tag has release to=Searchworks and value is true' do
      let(:release_data) { { 'Searchworks' => { 'release' => true } } }

      it 'returns true' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=searchworks (all lowercase) and value is true' do
      let(:release_data) { { 'searchworks' => { 'release' => true } } }

      it 'returns true' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      let(:release_data) { { 'SearchWorks' => { 'release' => true } } }

      it 'returns true' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=Searchworks and value is false' do
      let(:release_data) { { 'Searchworks' => { 'release' => false } } }

      it 'returns false' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when release_data tag has release to=Searchworks but no specified release value' do
      let(:release_data) { { 'Searchworks' => { 'bogus' => 'yup' } } }

      it 'returns false' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when there are no release tags at all' do
      let(:release_data) { {} }

      it 'returns false' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_2)
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when there are non searchworks related release tags' do
      let(:release_data) { { 'Revs' => { 'release' => true } } }

      it 'returns false' do
        setup_test_objects('druid:aa111aa1111', build_identity_metadata_1)
        expect(umrs.released_to_searchworks?).to be false
      end
    end
  end

  describe 'dor_items_for_constituents' do
    it 'returns empty array if no relationships' do
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
