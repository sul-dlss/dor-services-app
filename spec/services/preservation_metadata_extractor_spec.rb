# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservationMetadataExtractor do
  let(:workspace) { instance_double(DruidTools::Druid, path: 'foo') }
  let(:druid) { 'druid:nc893zj8956' }
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

  describe '.extract' do
    subject(:extract) { instance.extract }

    let(:metadata_dir) { instance_double(Pathname) }
    let(:workflow_path) { instance_double(Pathname, exist?: false, open: true) }
    let(:version_path) { instance_double(Pathname, exist?: false, open: true) }
    let(:content_path) { instance_double(Pathname, exist?: false, open: true) }
    let(:workflow_file) { instance_double(File, :<< => nil) }
    let(:version_file) { instance_double(File, :<< => nil) }
    let(:content_file) { instance_double(File, :<< => nil) }

    before do
      allow(workspace).to receive(:path).with('metadata', true).and_return('metadata_dir')
      expect(Pathname).to receive(:new).with('metadata_dir').and_return(metadata_dir)
      allow(Pathname).to receive(:new).and_call_original
      allow(metadata_dir).to receive(:join).with('workflows.xml').and_return(workflow_path)
      allow(metadata_dir).to receive(:join).with('versionMetadata.xml').and_return(version_path)
      allow(metadata_dir).to receive(:join).with('contentMetadata.xml').and_return(content_path)

      allow(instance).to receive(:extract_cocina)
      allow(workflow_path).to receive(:open).and_yield(workflow_file)
      allow(version_path).to receive(:open).and_yield(version_file)
      allow(content_path).to receive(:open).and_yield(content_file)

      stub_request(:get, 'https://workflow.example.com/workflow/objects/druid:nc893zj8956/workflows')
        .to_return(status: 200, body: '<workflow-stuff />', headers: {})
      allow(VersionMigrationService).to receive(:find_and_migrate)
    end

    it 'extracts the metadata' do
      extract
      expect(workflow_file).to have_received(:<<).with('<workflow-stuff />')
      expect(version_file).to have_received(:<<)
        .with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<versionMetadata objectId=\"druid:nc893zj8956\"/>\n")
      expect(content_file).to have_received(:<<)
        .with("<?xml version=\"1.0\"?>\n<contentMetadata objectId=\"druid:nc893zj8956\" type=\"book\"/>\n")

      expect(instance).to have_received(:extract_cocina)
    end
  end

  describe '#extract_cocina' do
    let(:metadata_dir) { instance_double(Pathname) }
    let(:metadata_file) { instance_double(Pathname, exist?: false) }
    let(:file) { instance_double(File, :<< => nil) }

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
      expect(file).to have_received(:<<)
        .with("{\n  \"cocinaVersion\": \"0.0.1\",\n  \"type\": \"#{Cocina::Models::Vocab.book}\",\n  \"externalIdentifier\": \"druid:nc893zj8956\",\n  \"label\": \"Test DRO\",\n  \"version\": 1,\n  \"access\": {\n    \"access\": \"world\",\n    \"download\": \"world\"\n  },\n  \"administrative\": {\n    \"hasAdminPolicy\": \"druid:hy787xj5878\",\n    \"releaseTags\": [\n\n    ]\n  },\n  \"description\": {\n    \"title\": [\n      {\n        \"structuredValue\": [\n\n        ],\n        \"parallelValue\": [\n\n        ],\n        \"groupedValue\": [\n\n        ],\n        \"value\": \"Test DRO\",\n        \"identifier\": [\n\n        ],\n        \"note\": [\n\n        ],\n        \"appliesTo\": [\n\n        ]\n      }\n    ],\n    \"contributor\": [\n\n    ],\n    \"event\": [\n\n    ],\n    \"form\": [\n\n    ],\n    \"geographic\": [\n\n    ],\n    \"language\": [\n\n    ],\n    \"note\": [\n\n    ],\n    \"identifier\": [\n\n    ],\n    \"subject\": [\n\n    ],\n    \"relatedResource\": [\n\n    ],\n    \"marcEncodedData\": [\n\n    ],\n    \"purl\": \"https://purl.stanford.edu/nc893zj8956\"\n  }\n}")
    end
    # rubocop:enable Layout/LineLength
  end
end
