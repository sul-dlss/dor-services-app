# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateMarcRecordService do
  subject(:umrs) { described_class.new(cocina_object, thumbnail_service: thumbnail_service) }

  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }
  let(:release_service) { instance_double(ReleaseTags::IdentityMetadata, released_for: release_data) }
  let(:release_data) { {} }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }

  let(:cocina_object) { build(:dro, id: druid) }

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
  let(:access_world) do
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
  let(:access_world_stanford) do
    {
      view: 'world',
      download: 'stanford'
    }
  end
  let(:access_stanford_download_none) do
    {
      view: 'stanford',
      download: 'none',
      controlledDigitalLending: false
    }
  end
  let(:access_stanford_cdl) do
    {
      view: 'stanford',
      download: 'none',
      controlledDigitalLending: true
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

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:update)
    end

    it 'invokes #update on a new instance' do
      described_class.update(cocina_object, thumbnail_service: thumbnail_service)
      expect(instance).to have_received(:update).once
    end
  end

  context 'when a druid without a catkey' do
    it 'does nothing' do
      expect(umrs).not_to receive(:push_symphony_records)
      umrs.update
    end
  end

  context 'when a druid with a catkey' do
    let(:cocina_object) do
      build(:dro, id: druid).new(identification: identity_metadata_catkey_barcode)
    end

    it 'executes the UpdateMarcRecordService push_symphony_records method' do
      expect(umrs.generate_symphony_records).to eq(["8832162\t#{druid.gsub('druid:', '')}\t"])
      expect(umrs).to receive(:push_symphony_records)
      umrs.update
    end
  end

  describe '.push_symphony_records' do
    it 'calls the relevant methods' do
      expect(umrs).to receive(:generate_symphony_records).once
      expect(umrs).to receive(:write_symphony_records).once
      umrs.push_symphony_records
    end
  end

  describe '.generate_symphony_records' do
    subject(:generate_symphony_records) { umrs.generate_symphony_records }

    let(:collection) do
      build(:collection, id: collection_druid, title: 'Collection label & A Special character').new(
        identification: identity_metadata_collection
      )
    end
    let(:release_data) { { 'Searchworks' => { 'release' => true } } }

    before do
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
    end

    context "when the druid object doesn't have catkey or previous catkeys" do
      it 'generates an empty array' do
        expect(generate_symphony_records).to eq []
      end
    end

    context 'when an item object has a catkey' do
      let(:cocina_object) do
        build(:dro, id: druid, title: 'Constituent label & A Special character').new(
          identification: identity_metadata_catkey_barcode,
          access: access_world,
          structural: structural_metadata
        )
      end

      it 'generates a single symphony record' do
        expect(generate_symphony_records).to eq [
          "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world"
        ]
      end
    end

    context 'when an object is stanford only and has a catkey' do
      let(:cocina_object) do
        build(:dro, id: druid, title: 'Constituent label & A Special character').new(
          identification: identity_metadata_catkey_barcode,
          access: access_stanford_only,
          structural: structural_metadata
        )
      end

      it 'generates symphony record with a z subfield' do
        expect(generate_symphony_records).to match_array [
          "8832162\tbc123dg9393\t.856. 41|zAvailable to Stanford-affiliated users.|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:group=stanford"
        ]
      end
    end

    context 'when an object has both previous and current catkeys' do
      let(:cocina_object) do
        build(:dro, id: druid, title: 'Constituent label & A Special character').new(
          identification: identity_metadata_previous_ckey,
          access: access_world,
          structural: structural_metadata
        )
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
      let(:cocina_object) do
        build(:dro, id: druid, title: 'Constituent label & A Special character').new(
          identification: {
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
        )
      end

      it 'generates blank symphony records for an item object' do
        expect(generate_symphony_records).to match_array %W[123\tbc123dg9393\t 456\tbc123dg9393\t]
      end
    end

    context 'when an collection object has a catkey' do
      let(:cocina_object) do
        build(:collection, id: collection_druid, title: 'Collection label & A Special character').new(
          access: {
            view: 'world'
          },
          identification: identity_metadata_collection
        )
      end

      it 'generates a single symphony record' do
        expect(generate_symphony_records).to match_array ["8832162\tcc111cc1111\t.856. 41|uhttps://purl.stanford.edu/cc111cc1111|xSDR-PURL|xcollection|xrights:world"]
      end
    end

    context 'when an collection object does not include identification' do
      let(:cocina_object) do
        build(:collection, id: collection_druid, title: 'Collection label & A Special character').new(
          access: {
            view: 'world'
          }
        )
      end

      it 'generates an empty symphony record' do
        expect(generate_symphony_records).to match_array []
      end
    end

    context 'when an APO object is passed' do
      let(:cocina_object) do
        build(:admin_policy, id: collection_druid).new(
          administrative: {
            hasAdminPolicy: apo_druid,
            hasAgreement: apo_druid,
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it 'generates a single symphony record' do
        expect(generate_symphony_records).to match_array []
      end
    end
  end

  describe '.write_symphony_records' do
    subject(:writer) { umrs.write_symphony_records marc_records }

    let(:fixtures) { './spec/fixtures' }
    let(:output_file) do
      "#{fixtures}/sdr_purl/sdr-purl-856s"
    end

    before do
      Settings.release.symphony_path = "#{fixtures}/sdr_purl"
    end

    after do
      FileUtils.rm_f(output_file)
    end

    context 'when a single record' do
      let(:marc_records) { ['abcdef'] }

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'when multiple records including special characters' do
      let(:marc_records) { %w[ab!#cdef 12@345 thirdrecord'withquote fourthrecordwith"doublequote] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records[0]}\n#{marc_records[1]}\n#{marc_records[2]}\n#{marc_records[3]}\n"
      end
    end

    context 'when an empty array' do
      let(:marc_records) { [] }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end

    context 'when nil' do
      let(:marc_records) { nil }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end

    context 'when a record with single quotes' do
      let(:marc_records) { ["this is | a record | that has 'single quotes' in it | and it should work"] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'when a record with double and single quotes' do
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
        build(:dro, id: druid).new(
          access: access_world
        )
      end

      it 'returns a blank z message' do
        expect(umrs.get_z_field).to eq('')
      end
    end

    context 'when a stanford only object' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: access_stanford_only
        )
      end

      it 'returns a non-blank z message' do
        expect(umrs.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
      end
    end

    context 'when a location restricted object' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: access_location
        )
      end

      it 'returns a non-blank z message for a location restricted object' do
        expect(umrs.get_z_field).to eq('|zAvailable to Stanford-affiliated users.')
      end
    end
  end

  describe '.get_856_cons' do
    it 'returns a valid sdrpurl constant' do
      expect(umrs.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    it 'returns 4' do
      expect(umrs.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    context 'with a non born digital APO' do
      it 'returns 1 for a non born digital APO' do
        expect(umrs.get_2nd_indicator).to eq('1')
      end
    end

    context 'with a born digital APO' do
      let(:cocina_object) { build(:dro, id: druid, admin_policy_id: 'druid:bx911tp9024') }

      it 'returns 0 for an EEMs APO' do
        expect(umrs.get_2nd_indicator).to eq('0')
      end
    end
  end

  describe '.get_u_field' do
    it 'returns valid purl url' do
      expect(umrs.get_u_field).to eq('|uhttps://purl.stanford.edu/bc123dg9393')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    it 'returns a valid sdrpurl constant' do
      expect(umrs.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    let(:cocina_object) do
      build(:dro, id: druid).new(
        structural: {
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
      )
    end
    let(:collection) do
      build(:collection, id: collection_druid, title: 'Collection label & A Special character').new(
        identification: identity_metadata_collection
      )
    end

    it 'returns an empty string for an object without collection' do
      expect(umrs.get_x2_collection_info).to be_empty
    end

    context 'when a collection object' do
      it 'returns an empty string' do
        expect(umrs.get_x2_collection_info).to be_empty
      end
    end

    context 'when an object with a collection' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          structural: structural_metadata
        )
      end

      it 'returns the appropriate information for the collection object' do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
        expect(umrs.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label & A Special character')
      end
    end
  end

  describe '#get_x2_part_info' do
    context 'with descMetadata without part information' do
      it 'returns an empty string for objects with part information' do
        expect(umrs.get_x2_part_info).to be_empty
      end
    end

    context 'with descMetadata with some part numbers' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:55th legislature, 1997-1998'
      end
    end

    context 'with descMetadata with a part name and number' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns a part label' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with a sequential designation in a note' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:123'
      end
    end

    context 'with descMetadata does not include a note' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with a sequential designation on a part number' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns both the label and part number' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011|xsort:2011'
      end
    end

    context 'with descMetadata with multiple titles, one of them marked as the primary title' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
            title: [
              {
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
        )
      end

      it 'returns the label from the primary title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with multiple titles' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
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
        )
      end

      it 'returns the label from the first title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3. 2011'
      end
    end

    context 'with descMetadata with parallel title' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
            title: [
              {
                parallelValue: [
                  {
                    structuredValue: [
                      {
                        value: 'Some label',
                        type: 'main title'
                      },
                      {
                        value: 'Issue #3',
                        type: 'part name'
                      }
                    ]
                  },
                  {
                    value: 'Some other label'
                  }
                ]
              }
            ],
            purl: "https://purl.stanford.edu/#{bare_druid}"
          }
        )
      end

      it 'returns the label from the parallel title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3'
      end
    end

    context 'with descMetadata with parallel title with a sequential designation in a note' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          description: {
            title: [
              {
                parallelValue: [
                  {
                    structuredValue: [
                      {
                        value: 'Some label',
                        type: 'main title'
                      },
                      {
                        value: 'Issue #3',
                        type: 'part name'
                      }
                    ]
                  },
                  {
                    value: 'Some other label'
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
        )
      end

      it 'returns the label from the parallel title' do
        expect(umrs.get_x2_part_info).to eq '|xlabel:Issue #3|xsort:123'
      end
    end
  end

  describe '#get_x2_rights_info' do
    subject(:rights_info) { umrs.get_x2_rights_info }

    context 'with world rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_world)
      end

      it { is_expected.to eq '|xrights:world' }
    end

    context 'with stanford-only rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_only)
      end

      it { is_expected.to eq '|xrights:group=stanford' }
    end

    context 'with view-world stanford-download rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_world_stanford)
      end

      it { is_expected.to eq '' }
    end

    context 'with stanford-only download none rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_download_none)
      end

      it { is_expected.to eq '' }
    end

    context 'with CDL rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_cdl)
      end

      it { is_expected.to eq '|xrights:cdl' }
    end

    context 'with location rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_location)
      end

      it { is_expected.to eq '|xrights:location=spec' }
    end

    context 'with citation rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: {
            view: 'world',
            download: 'none'
          }
        )
      end

      it { is_expected.to eq '|xrights:citation' }
    end

    context 'with dark rights' do
      it { is_expected.to eq '|xrights:dark' }
    end
  end

  describe 'Released to Searchworks' do
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

    context 'with valid structural metadata' do
      let(:cocina_object) { build(:dro, id: druid).new(structural: structural_metadata) }

      it 'returns a thumb' do
        expect(thumb).to eq 'bc123dg9393%2Fwt183gy6220_00_0001.jp2'
      end
    end

    context 'with no structural metadata' do
      it 'returns nil' do
        expect(thumb).to be_nil
      end
    end
  end

  describe '#previous_ckeys' do
    subject(:previous_ckeys) { umrs.send :previous_ckeys }

    context 'when previous_catkeys exists' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          identification: identity_metadata_previous_ckey
        )
      end

      it 'returns values for previous catkeys in identityMetadata' do
        expect(previous_ckeys).to eq(%w[123 456])
      end
    end

    context 'when previous_catkeys are empty' do
      it 'returns an empty array for previous catkeys in identityMetadata without either' do
        expect(previous_ckeys).to eq([])
      end
    end
  end
end
