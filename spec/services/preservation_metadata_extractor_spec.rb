# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservationMetadataExtractor do
  let(:workspace) { instance_double(DruidTools::Druid, path: 'foo') }
  let(:druid) { 'druid:nc893zj8956' }
  let(:item) { instance_double(Dor::Item, pid: druid) }
  let(:instance) { described_class.new(workspace: workspace, cocina_object: cocina_object) }
  let(:cocina_object) do
    Cocina::Models::DRO.new({
                              cocinaVersion: '0.0.1',
                              externalIdentifier: druid,
                              type: Cocina::Models::Vocab.book,
                              label: 'Test DRO',
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                              },
                              version: 1,
                              access: { access: 'world', download: 'world' },
                              administrative: { hasAdminPolicy: 'druid:hy787xj5878' }
                            })
  end

  before do
    allow(Dor).to receive(:find).and_return(item)
  end

  describe '.extract' do
    subject(:extract) { instance.extract }

    let(:metadata_dir) { instance_double(Pathname) }
    let(:metadata_file) { instance_double(Pathname, exist?: false) }
    let(:metadata_string) { '<metadata/>' }

    before do
      allow(workspace).to receive(:path).with('metadata', true).and_return('metadata_dir')
      expect(Pathname).to receive(:new).with('metadata_dir').and_return(metadata_dir)
      expect(metadata_dir).to receive(:join).at_least(6).times.and_return(metadata_file)
      expect(metadata_file).to receive(:open).at_least(6).times
      allow(instance).to receive(:datastream_content).and_return(metadata_string)
      allow(instance).to receive(:extract_cocina)
    end

    it 'extracts the metadata' do
      extract
      expect(instance).to have_received(:datastream_content).with(item, :administrativeMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :contentMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :defaultObjectRights, false)
      expect(instance).to have_received(:datastream_content).with(item, :descMetadata, true).once
      expect(instance).to have_received(:datastream_content).with(item, :events, false)
      expect(instance).to have_received(:datastream_content).with(item, :geoMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :embargoMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :identityMetadata, true)
      expect(instance).to have_received(:datastream_content).with(item, :provenanceMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :relationshipMetadata, true)
      expect(instance).to have_received(:datastream_content).with(item, :roleMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :sourceMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :rightsMetadata, false)
      expect(instance).to have_received(:datastream_content).with(item, :versionMetadata, true)
      expect(instance).to have_received(:datastream_content).with(item, :workflows, false)
      expect(instance).to have_received(:extract_cocina)
    end
  end

  describe '#datastream_content' do
    subject(:datastream_content) { instance.send(:datastream_content, item, ds_name, required) }

    let(:ds_name) { :myMetadata }
    let(:datastream) { instance_double(Dor::ContentMetadataDS) }
    let(:required) { true }

    before do
      allow(item).to receive(:datastreams).and_return('myMetadata' => datastream)
    end

    it 'retrieves content of a required datastream' do
      metadata_string = '<metadata/>'
      expect(datastream).to receive(:new?).and_return(false)
      expect(datastream).to receive(:content).and_return(metadata_string)
      expect(datastream_content).to eq metadata_string
    end

    context 'when datastream is workflows' do
      let(:ds_name) { :workflows }
      let(:client) { instance_double(Dor::Workflow::Client, all_workflows_xml: '<workflows />') }

      before do
        allow(WorkflowClientFactory).to receive(:build).and_return(client)
      end

      it { is_expected.to eq '<workflows />' }
    end

    context 'when datastream is versionMetadata' do
      let(:ds_name) { :versionMetadata }

      let(:expected_xml) { '<versionMetadata />' }

      before do
        allow(VersionMigrationService).to receive(:migrate)
        allow(ObjectVersion).to receive(:version_xml).and_return(expected_xml)
      end

      it { is_expected.to be_equivalent_to expected_xml }
    end

    context 'when datastream is contentMetadata' do
      let(:ds_name) { :contentMetadata }
      let(:structural) do
        {
          contains: [{
            type: Cocina::Models::Vocab::Resources.image,
            externalIdentifier: 'wt183gy6220',
            label: 'Image 1',
            version: 1,
            structural: {
              contains: [{
                type: Cocina::Models::Vocab.file,
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
              }]
            }
          }]
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new({
                                  cocinaVersion: '0.0.1',
                                  externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.book,
                                  label: 'Test DRO',
                                  version: 1,
                                  description: {
                                    title: [{ value: 'Test DRO' }],
                                    purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                  },
                                  access: { access: 'world', download: 'world' },
                                  administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                  structural: structural
                                })
      end

      let(:fileset_id) { 'http://cocina.sul.stanford.edu/fileSet/3f231c45-5af9-4530-bea9-f99982e394fb' }
      let(:expected_xml) do
        <<~XML
          <contentMetadata objectId="druid:nc893zj8956" type="book">\n
            <resource id="http://cocina.sul.stanford.edu/fileSet/3f231c45-5af9-4530-bea9-f99982e394fb" sequence="1" type="image">\n
              <label>Image 1</label>\n
              <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927" publish="no" shelve="no" preserve="no"/>\n
            </resource>\n
          </contentMetadata>
        XML
      end

      before do
        allow(Cocina::IdGenerator).to receive(:generate_or_existing_fileset_id).and_return(fileset_id)
      end

      it 'returns the correct datastream xml' do
        expect(datastream_content).to be_equivalent_to expected_xml
      end

      context 'when cocina structural is nil (APOs, collections)' do
        let(:cocina_object) do
          Cocina::Models::Collection.new({
                                           cocinaVersion: '0.0.1',
                                           externalIdentifier: druid,
                                           type: Cocina::Models::Vocab.collection,
                                           label: 'Test Collection',
                                           version: 1,
                                           description: {
                                             title: [{ value: 'Test Collection' }],
                                             purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                           },
                                           access: { access: 'world' },
                                           administrative: { hasAdminPolicy: 'druid:hy787xj5878' }
                                         })
        end

        it 'returns nil' do
          expect(datastream_content).to be_nil
        end
      end
    end

    context 'when datastream is empty or missing' do
      let(:ds_name) { :dummy }

      before do
        expect(datastream).not_to receive(:content)
      end

      context 'when the datastream is optional' do
        let(:required) { false }

        it { is_expected.to be_nil }
      end

      context 'when the datastream is required' do
        it 'raises an error' do
          expect { datastream_content }.to raise_exception(RuntimeError)
        end
      end
    end
  end

  describe '#extract_cocina' do
    let(:metadata_dir) { instance_double(Pathname) }
    let(:metadata_file) { instance_double(Pathname, exist?: false) }
    let(:file) { instance_double(File, :<< => nil) }
    # let(:metadata_string) { '<metadata/>' }

    before do
      allow(workspace).to receive(:path).with('metadata', true).and_return('metadata_dir')
      expect(Pathname).to receive(:new).with('metadata_dir').and_return(metadata_dir)
      allow(metadata_dir).to receive(:join).and_return(metadata_file)
      allow(metadata_file).to receive(:open).and_yield(file)
    end

    # rubocop:disable Layout/LineLength
    it 'serializes json' do
      instance.send(:extract_cocina)
      expect(metadata_dir).to have_received(:join).with('cocina.json')
      expect(file).to have_received(:<<).with("{\n  \"cocinaVersion\": \"0.0.1\",\n  \"type\": \"http://cocina.sul.stanford.edu/models/book.jsonld\",\n  \"externalIdentifier\": \"druid:nc893zj8956\",\n  \"label\": \"Test DRO\",\n  \"version\": 1,\n  \"access\": {\n    \"access\": \"world\",\n    \"download\": \"world\"\n  },\n  \"administrative\": {\n    \"hasAdminPolicy\": \"druid:hy787xj5878\",\n    \"releaseTags\": [\n\n    ]\n  },\n  \"description\": {\n    \"title\": [\n      {\n        \"structuredValue\": [\n\n        ],\n        \"parallelValue\": [\n\n        ],\n        \"groupedValue\": [\n\n        ],\n        \"value\": \"Test DRO\",\n        \"identifier\": [\n\n        ],\n        \"note\": [\n\n        ],\n        \"appliesTo\": [\n\n        ]\n      }\n    ],\n    \"contributor\": [\n\n    ],\n    \"event\": [\n\n    ],\n    \"form\": [\n\n    ],\n    \"geographic\": [\n\n    ],\n    \"language\": [\n\n    ],\n    \"note\": [\n\n    ],\n    \"identifier\": [\n\n    ],\n    \"subject\": [\n\n    ],\n    \"relatedResource\": [\n\n    ],\n    \"marcEncodedData\": [\n\n    ],\n    \"purl\": \"https://purl.stanford.edu/nc893zj8956\"\n  }\n}")
    end
    # rubocop:enable Layout/LineLength
  end
end
