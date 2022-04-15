# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::UpdateMarcRecordService do
  subject(:umrs) { described_class.new(cocina_object, thumbnail_service: thumbnail_service) }

  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }
  let(:dro_object_label) { 'A generic label' }
  let(:collection_label) { 'A collection label' }
  let(:release_service) { instance_double(ReleaseTags::IdentityMetadata, released_for: release_data) }
  let(:release_data) { {} }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }

  let(:descriptive_metadata_basic) do
    {
      title: [{ value: 'Constituent label & A Special character' }],
      purl: "https://purl.stanford.edu/#{bare_druid}"
    }
  end
  let(:collection_descriptive_metadata_basic) do
    {
      title: [{ value: 'Collection label & A Special character' }],
      purl: "https://purl.stanford.edu/#{collection_bare_druid}"
    }
  end
  let(:identity_metadata_basic) do
    {
      sourceId: 'sul:36105216275185'
    }
  end
  let(:identity_metadata_catkey_barcode) do
    {
      sourceId: 'sul:36105216275185',
      catalogLinks: [{
        catalog: 'symphony',
        catalogRecordId: '8832162',
        refresh: true
      }],
      barcode: '36105216275185'
    }
  end
  let(:identity_metadata_collection) do
    {
      sourceId: 'sul:36105216275185',
      catalogLinks: [{
        catalog: 'symphony',
        catalogRecordId: '8832162',
        refresh: true
      }]
    }
  end
  let(:identity_metadata_previous_ckey) do
    {
      sourceId: 'sul:36105216275185',
      catalogLinks: [
        {
          catalog: 'symphony',
          catalogRecordId: '8832162',
          refresh: true
        },
        {
          catalog: 'previous symphony',
          catalogRecordId: '123',
          refresh: false
        },
        {
          catalog: 'previous symphony',
          catalogRecordId: '456',
          refresh: false
        }
      ]
    }
  end
  let(:attachment1) do
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: 'wt183gy6220_1',
      label: 'Image 1',
      filename: 'wt183gy6220_00_0001.jp2',
      hasMimeType: 'image/jp2',
      size: 3_182_927,
      version: 1,
      access: {},
      administrative: {
        publish: false,
        sdrPreserve: false,
        shelve: false
      },
      hasMessageDigests: []
    }
  end
  let(:structural_metadata) do
    {
      contains: [{
        type: Cocina::Models::FileSetType.image,
        externalIdentifier: 'wt183gy6220',
        label: 'Image 1',
        version: 1,
        structural: {
          contains: [attachment1]
        }
      }],
      isMemberOf: ['druid:cc111cc1111']
    }
  end
  let(:access_word) do
    {
      view: 'world',
      download: 'world'
    }
  end
  let(:access_stanford_only) do
    {
      view: 'stanford',
      download: 'stanford'
    }
  end
  let(:access_location) do
    {
      view: 'location-based',
      download: 'location-based',
      location: 'spec'
    }
  end

  before do
    allow(ReleaseTags::IdentityMetadata).to receive(:for).and_return(release_service)
    Settings.release.symphony_path = './spec/fixtures/sdr-purl'
  end

  describe '.update' do
    let(:instance) { described_class.new(cocina_object, thumbnail_service: thumbnail_service) }
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: identity_metadata_basic,
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: {})
    end

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:update)
    end

    it 'invokes #update on a new instance' do
      described_class.update(cocina_object, thumbnail_service: thumbnail_service)
      expect(instance).to have_received(:update).once
    end
  end

  context 'for a druid without a catkey' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: identity_metadata_basic,
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: {})
    end

    it 'does nothing' do
      expect(umrs).not_to receive(:push_symphony_records)
      umrs.update
    end
  end

  context 'for a druid with a catkey' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: identity_metadata_catkey_barcode,
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: {})
    end

    it 'executes the UpdateMarcRecordService push_symphony_records method' do
      expect(umrs.generate_symphony_records).to eq(["8832162\t#{druid.gsub('druid:', '')}\t"])
      expect(umrs).to receive(:push_symphony_records)
      umrs.update
    end
  end

  describe '.push_symphony_records' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: identity_metadata_basic,
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: {})
    end

    it 'calls the relevant methods' do
      expect(umrs).to receive(:generate_symphony_records).once
      expect(umrs).to receive(:write_symphony_records).once
      umrs.push_symphony_records
    end
  end

  describe '.generate_symphony_records' do
    subject(:generate_symphony_records) { umrs.generate_symphony_records }

    let(:collection) do
      Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                     type: Cocina::Models::ObjectType.collection,
                                     label: collection_label,
                                     version: 1,
                                     description: collection_descriptive_metadata_basic,
                                     access: {},
                                     administrative: { hasAdminPolicy: apo_druid },
                                     identification: identity_metadata_collection)
    end
    let(:release_data) { { 'Searchworks' => { 'release' => true } } }

    before do
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
    end

    context "when the druid object doesn't have catkey or previous catkeys" do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'generates an empty array' do
        expect(generate_symphony_records).to eq []
      end
    end

    context 'when an item object has a catkey' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: identity_metadata_catkey_barcode,
                                access: access_word,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'generates a single symphony record' do
        # rubocop:disable Layout/LineLength
        expect(generate_symphony_records).to eq [
          "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world"
        ]
      end
    end

    context 'when an object is stanford only and has a catkey' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: identity_metadata_catkey_barcode,
                                access: access_stanford_only,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'generates symphony record with a z subfield' do
        expect(generate_symphony_records).to match_array [
          "8832162\tbc123dg9393\t.856. 41|zAvailable to Stanford-affiliated users.|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:group=stanford"
        ]
      end
    end

    context 'when an object has both previous and current catkeys' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: identity_metadata_previous_ckey,
                                access: access_word,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'generates blank symphony records and a regular symphony record' do
        expect(generate_symphony_records).to match_array [
          "123\tbc123dg9393\t",
          "456\tbc123dg9393\t",
          "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world"
        ]
      end
    end

    context 'when an object has only previous catkeys' do
      let(:identification) do
        {
          sourceId: 'sul:36105216275185',
          barcode: '36105216275185',
          catalogLinks: [
            {
              catalog: 'previous symphony',
              catalogRecordId: '123',
              refresh: false
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '456',
              refresh: false
            }
          ]
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: identification,
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: {})
      end

      it 'generates blank symphony records for an item object' do
        expect(generate_symphony_records).to match_array %W(123\tbc123dg9393\t 456\tbc123dg9393\t)
      end
    end

    context 'when an collection object has a catkey' do
      let(:access) do
        {
          view: 'world'
        }
      end
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                       type: Cocina::Models::ObjectType.collection,
                                       label: collection_label,
                                       version: 1,
                                       description: collection_descriptive_metadata_basic,
                                       access: access,
                                       identification: identity_metadata_collection,
                                       administrative: { hasAdminPolicy: apo_druid })
      end

      it 'generates a single symphony record' do
        expect(generate_symphony_records).to match_array ["8832162\tcc111cc1111\t.856. 41|uhttps://purl.stanford.edu/cc111cc1111|xSDR-PURL|xcollection|xrights:world"]
      end
    end

    context 'when an collection object does not include idenfitication' do
      let(:access) do
        {
          view: 'world'
        }
      end
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                       type: Cocina::Models::ObjectType.collection,
                                       label: collection_label,
                                       version: 1,
                                       description: collection_descriptive_metadata_basic,
                                       access: access,
                                       administrative: { hasAdminPolicy: apo_druid },
                                       identification: { sourceId: 'sul:123' })
      end

      it 'generates an empty symphony record' do
        expect(generate_symphony_records).to match_array []
      end
    end

    context 'when an collection object includes empty idenfitication' do
      let(:access) do
        {
          view: 'world'
        }
      end
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                       type: Cocina::Models::ObjectType.collection,
                                       label: collection_label,
                                       version: 1,
                                       description: collection_descriptive_metadata_basic,
                                       access: access,
                                       identification: { sourceId: 'sul:123' },
                                       administrative: { hasAdminPolicy: apo_druid })
      end

      it 'generates an empty symphony record' do
        expect(generate_symphony_records).to match_array []
      end
    end

    context 'when an APO object is passed' do
      let(:access) do
        {
          view: 'world'
        }
      end
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: collection_druid,
                                        type: Cocina::Models::ObjectType.admin_policy,
                                        label: collection_label,
                                        version: 1,
                                        administrative: {
                                          hasAdminPolicy: apo_druid,
                                          hasAgreement: apo_druid,
                                          accessTemplate: { view: 'world', download: 'world' }
                                        })
      end

      it 'generates a single symphony record' do
        expect(generate_symphony_records).to match_array []
      end
    end
  end

  describe '.write_symphony_records' do
    subject(:writer) { umrs.write_symphony_records marc_records }

    let(:fixtures) { './spec/fixtures' }
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    let(:output_file) do
      "#{fixtures}/sdr_purl/sdr-purl-856s"
    end

    before do
      Settings.release.symphony_path = "#{fixtures}/sdr_purl"
      expect(File).not_to exist(output_file)
    end

    after do
      FileUtils.rm_f(output_file)
    end

    context 'for a single record' do
      let(:marc_records) { ['abcdef'] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'for multiple records including special characters' do
      let(:marc_records) { %w(ab!#cdef 12@345 thirdrecord'withquote fourthrecordwith"doublequote) }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records[0]}\n#{marc_records[1]}\n#{marc_records[2]}\n#{marc_records[3]}\n"
      end
    end

    context 'for an empty array' do
      let(:marc_records) { [] }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end

    context 'for nil' do
      let(:marc_records) { nil }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end

    context 'for a record with single quotes' do
      let(:marc_records) { ["this is | a record | that has 'single quotes' in it | and it should work"] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'for a record with double and single quotes' do
      let(:marc_records) { ['record with "double quotes" in it | and it should work'] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end
  end

  describe '.get_z_field' do
    context 'with rights metadata world' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_word,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a blank z message' do
        expect(umrs.get_z_field).to eq('')
      end
    end

    context 'for a stanford only object' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_stanford_only,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a non-blank z message' do
        expect(umrs.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
      end
    end

    context 'for a location restricted object' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_location,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a non-blank z message for a location restricted object' do
        expect(umrs.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
      end
    end
  end

  describe '.get_856_cons' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    it 'returns a valid sdrpurl constant' do
      expect(umrs.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    it 'returns 4' do
      expect(umrs.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    context 'with a non born digital APO' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns 1 for a non born digital APO' do
        expect(umrs.get_2nd_indicator).to eq('1')
      end
    end

    context 'with a born digital APO' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:bx911tp9024' },
                                structural: structural_metadata)
      end

      it 'returns 0 for an EEMs APO' do
        expect(umrs.get_2nd_indicator).to eq('0')
      end
    end
  end

  describe '.get_u_field' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    it 'returns valid purl url' do
      expect(umrs.get_u_field).to eq('|uhttps://purl.stanford.edu/bc123dg9393')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    it 'returns a valid sdrpurl constant' do
      expect(umrs.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    let(:structural_metadata_no_collection) do
      {
        contains: [{
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'wt183gy6220',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [attachment1]
          }
        }]
      }
    end
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata_no_collection)
    end
    let(:collection) do
      Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                     type: Cocina::Models::ObjectType.collection,
                                     label: collection_label,
                                     description: collection_descriptive_metadata_basic,
                                     version: 1,
                                     access: {},
                                     administrative: { hasAdminPolicy: apo_druid },
                                     identification: identity_metadata_collection)
    end

    it 'returns an empty string for an object without collection' do
      expect(umrs.get_x2_collection_info).to be_empty
    end

    context 'for a collection object' do
      it 'returns an empty string' do
        expect(umrs.get_x2_collection_info).to be_empty
      end
    end

    context 'for an object with a collection' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns the appropriate information for the collection object' do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
        expect(umrs.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label & A Special character')
      end
    end
  end

  describe '#get_x2_part_info' do
    context 'with descMetadata without part information' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns an empty string for objects with part information' do
        expect(umrs.get_x2_part_info).to be_empty
      end
    end

    context 'with descMetadata with some part numbers' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: '55th legislature',
                  type: 'part number'
                },
                {
                  value: '1997-1998',
                  type: 'part number'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:55th legislature, 1997-1998'
      end
    end

    context 'with descMetadata with a part name and number' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with a sequential designation in a note' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}",
          note: [
            {
              value: '123',
              type: 'date/sequential designation'
            }
          ]

        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:123'
      end
    end

    context 'with descMetadata does not include a note' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with a sequential designation on a part number' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            }
          ],
          note: [
            {
              value: '2011',
              type: 'date/sequential designation'
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:2011'
      end
    end

    context 'with descMetadata with multiple titles, one of them marked as the primary title' do
      let(:description) do
        {
          title: [
            {
              value: 'Some label',
              status: 'primary',
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Some lie',
                  type: 'part name'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns the label from the primary title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with multiple titles' do
      let(:description) do
        {
          title: [
            {
              value: 'Some label',
              status: 'primary',
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Issue #3',
                  type: 'part name'
                },
                {
                  value: '2011',
                  type: 'part number'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Some label',
                  type: 'main title'
                },
                {
                  value: 'Some lie',
                  type: 'part name'
                }
              ]
            }
          ],
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: description,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns the label from the first title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end
  end

  describe '#get_x2_rights_info' do
    subject(:rights_info) { umrs.get_x2_rights_info }

    context 'world rights' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_word,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:world' }
    end

    context 'stanford-only rights' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_stanford_only,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:group=stanford' }
    end

    context 'CDL rights' do
      let(:access) do
        {
          view: 'world',
          download: 'stanford'
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:cdl' }
    end

    context 'location rights' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access_location,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:location=spec' }
    end

    context 'citation rights' do
      let(:access) do
        {
          view: 'world',
          download: 'none'
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: access,
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:citation' }
    end

    context 'no rights' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it { is_expected.to eq '|xrights:dark' }
    end
  end

  describe 'Released to Searchworks' do
    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    context 'when release_data tag has release to=Searchworks and value is true' do
      let(:release_data) { { 'Searchworks' => { 'release' => true } } }

      it 'returns true' do
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=searchworks (all lowercase) and value is true' do
      let(:release_data) { { 'searchworks' => { 'release' => true } } }

      it 'returns true' do
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      let(:release_data) { { 'SearchWorks' => { 'release' => true } } }

      it 'returns true' do
        expect(umrs.released_to_searchworks?).to be true
      end
    end

    context 'when release_data tag has release to=Searchworks and value is false' do
      let(:release_data) { { 'Searchworks' => { 'release' => false } } }

      it 'returns false' do
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when release_data tag has release to=Searchworks but no specified release value' do
      let(:release_data) { { 'Searchworks' => { 'bogus' => 'yup' } } }

      it 'returns false' do
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when there are no release tags at all' do
      let(:release_data) { {} }

      it 'returns false' do
        expect(umrs.released_to_searchworks?).to be false
      end
    end

    context 'when there are non searchworks related release tags' do
      let(:release_data) { { 'Revs' => { 'release' => true } } }

      it 'returns false' do
        expect(umrs.released_to_searchworks?).to be false
      end
    end
  end

  describe '#thumb' do
    subject(:thumb) { umrs.send(:thumb) }

    let(:cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label: dro_object_label,
                              version: 1,
                              description: descriptive_metadata_basic,
                              identification: { sourceId: 'sul:123' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid },
                              structural: structural_metadata)
    end

    context 'with valid structural metadata' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns a thumb' do
        expect(thumb).to eq 'bc123dg9393%2Fwt183gy6220_00_0001.jp2'
      end
    end

    context 'with no structural metadata' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: {})
      end

      it 'returns nil' do
        expect(thumb).to be_nil
      end
    end
  end

  describe '#previous_ckeys' do
    subject(:previous_ckeys) { umrs.send :previous_ckeys }

    context 'when previous_catkeys exists' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: identity_metadata_previous_ckey,
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns values for previous catkeys in identityMetadata' do
        expect(previous_ckeys).to eq(%w(123 456))
      end
    end

    context 'when previous_catkeys are empty' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.object,
                                label: dro_object_label,
                                version: 1,
                                description: descriptive_metadata_basic,
                                identification: { sourceId: 'sul:123' },
                                access: {},
                                administrative: { hasAdminPolicy: apo_druid },
                                structural: structural_metadata)
      end

      it 'returns an empty array for previous catkeys in identityMetadata without either' do
        expect(previous_ckeys).to eq([])
      end
    end
  end
end
