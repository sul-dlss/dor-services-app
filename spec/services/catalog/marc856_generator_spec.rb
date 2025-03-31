# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::Marc856Generator do
  subject(:marc_856_generator) { described_class.new(cocina_object, thumbnail_service:, catalog: 'symphony') }

  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }
  let(:release_data) { false }
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
    allow(ReleaseTagService).to receive(:released_to_searchworks?).and_return(release_data)
  end

  describe '.create' do
    let(:instance) { instance_double(described_class, create: true) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'invokes #create on a new instance' do
      described_class.create(cocina_object, thumbnail_service:, catalog: 'symphony')
      expect(described_class).to have_received(:new).with(cocina_object, thumbnail_service:, catalog: 'symphony')
      expect(instance).to have_received(:create).once
    end
  end

  describe '#create' do
    subject(:marc_856_data) { marc_856_generator.create }

    let(:collection) do
      build(:collection, id: collection_druid, title: 'Collection label & A Special character').new(
        identification: identity_metadata_collection
      )
    end
    let(:release_data) { true }

    before do
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
    end

    context 'when an item object has a catkey' do
      let(:cocina_object) do
        build(:dro, id: druid, title: 'Constituent label & A Special character').new(
          identification: identity_metadata_catkey_barcode,
          access: access_world,
          structural: structural_metadata
        )
      end
      let(:result) do
        {
          indicators: '41',
          subfields: [
            { code: 'u', value: "https://purl.stanford.edu/#{bare_druid}" },
            { code: 'x', value: 'SDR-PURL' },
            { code: 'x', value: 'item' },
            { code: 'x', value: 'barcode:36105216275185' },
            { code: 'x', value: "file:#{bare_druid}%2Fwt183gy6220_00_0001.jp2" },
            { code: 'x', value: "collection:#{collection_bare_druid}:8832162:Collection label & A Special character" },
            { code: 'x', value: 'rights:world' }
          ]
        }
      end

      it 'generates a MARC 856 data' do
        expect(marc_856_data).to eq result
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
      let(:result) do
        {
          indicators: '41',
          subfields: [
            { code: 'z', value: 'Available to Stanford-affiliated users.' },
            { code: 'u', value: "https://purl.stanford.edu/#{bare_druid}" },
            { code: 'x', value: 'SDR-PURL' },
            { code: 'x', value: 'item' },
            { code: 'x', value: 'barcode:36105216275185' },
            { code: 'x', value: "file:#{bare_druid}%2Fwt183gy6220_00_0001.jp2" },
            { code: 'x', value: "collection:#{collection_bare_druid}:8832162:Collection label & A Special character" },
            { code: 'x', value: 'rights:group=stanford' }
          ]
        }
      end

      it 'generates marc record with a z subfield' do
        expect(marc_856_data).to eq result
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
      let(:result) do
        {
          indicators: '41',
          subfields: [
            { code: 'u', value: "https://purl.stanford.edu/#{collection_bare_druid}" },
            { code: 'x', value: 'SDR-PURL' },
            { code: 'x', value: 'collection' },
            { code: 'x', value: 'rights:world' }
          ]
        }
      end

      it 'generates a single marc record' do
        expect(marc_856_data).to eq result
      end
    end
  end

  describe '.access' do
    context 'with rights metadata world' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: access_world
        )
      end

      it 'returns a blank access message' do
        expect(marc_856_generator.send(:subfield_z_access)).to be_nil
      end
    end

    context 'when a stanford only object' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: access_stanford_only
        )
      end

      it 'returns a non-blank access message' do
        expect(marc_856_generator.send(:subfield_z_access)).to eq({ code: 'z',
                                                                    value: 'Available to Stanford-affiliated users.' })
      end
    end

    context 'when a location restricted object' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: access_location
        )
      end

      it 'returns a non-blank access message for a location restricted object' do
        expect(marc_856_generator.send(:subfield_z_access)).to eq({ code: 'z',
                                                                    value: 'Available to Stanford-affiliated users.' })
      end
    end
  end

  describe '.collections' do
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
      expect(marc_856_generator.send(:subfield_x_collections)).to be_empty
    end

    context 'when a collection object' do
      it 'returns an empty string' do
        expect(marc_856_generator.send(:subfield_x_collections)).to be_empty
      end
    end

    context 'when an object with a collection that is not released to searchworks' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          structural: structural_metadata
        )
      end

      it 'does not return information for the collection object' do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
        expect(marc_856_generator.send(:subfield_x_collections)).to eq([])
      end
    end

    context 'when an object with a collection that is released to searchworks' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          structural: structural_metadata
        )
      end

      let(:release_data) { true }
      let(:result) do
        [{ code: 'x', value: 'collection:cc111cc1111:8832162:Collection label & A Special character' }]
      end

      it 'returns the appropriate information for the collection object' do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
        expect(marc_856_generator.send(:subfield_x_collections)).to eq result
      end
    end
  end

  describe '#parts' do
    context 'with descMetadata without part information' do
      it 'returns an empty string for objects with part information' do
        expect(marc_856_generator.send(:subfield_x_parts)).to be_nil
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x',
                                                                    value: 'label:55th legislature, 1997-1998' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' },
                                                                  { code: 'x', value: 'sort:123' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' },
                                                                  { code: 'x', value: 'sort:2011' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3. 2011' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3' }])
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
        expect(marc_856_generator.send(:subfield_x_parts)).to eq([{ code: 'x', value: 'label:Issue #3' },
                                                                  { code: 'x', value: 'sort:123' }])
      end
    end
  end

  describe '#rights' do
    subject(:rights_info) { marc_856_generator.send :subfield_x_rights }

    context 'with world rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_world)
      end

      it { is_expected.to eq [{ code: 'x', value: 'rights:world' }] }
    end

    context 'with stanford-only rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_only)
      end

      it { is_expected.to eq [{ code: 'x', value: 'rights:group=stanford' }] }
    end

    context 'with view-world stanford-download rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_world_stanford)
      end

      it { is_expected.to eq [] }
    end

    context 'with stanford-only download none rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_download_none)
      end

      it { is_expected.to eq [] }
    end

    context 'with CDL rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_stanford_cdl)
      end

      it { is_expected.to eq [{ code: 'x', value: 'rights:cdl' }] }
    end

    context 'with location rights' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access: access_location)
      end

      it { is_expected.to eq [{ code: 'x', value: 'rights:location=spec' }] }
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

      it { is_expected.to eq [{ code: 'x', value: 'rights:citation' }] }
    end

    context 'with dark rights' do
      it { is_expected.to eq [{ code: 'x', value: 'rights:dark' }] }
    end
  end

  describe '#thumbnail' do
    subject(:thumb) { marc_856_generator.send(:subfield_x_thumbnail) }

    context 'with valid structural metadata' do
      let(:cocina_object) { build(:dro, id: druid).new(structural: structural_metadata) }

      it 'returns a thumb' do
        expect(thumb).to eq({ code: 'x', value: 'file:bc123dg9393%2Fwt183gy6220_00_0001.jp2' })
      end
    end

    context 'with no structural metadata' do
      it 'returns nil' do
        expect(thumb).to be_nil
      end
    end
  end
end
