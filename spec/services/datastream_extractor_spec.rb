# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatastreamExtractor do
  let(:workspace) { instance_double(DruidTools::Druid, path: 'foo') }
  let(:druid) { 'druid:nc893zj8956' }
  let(:item) { instance_double(Dor::Item, pid: druid) }
  let(:instance) { described_class.new(item: item, workspace: workspace) }

  describe '.extract_datastreams' do
    subject(:extract_datastreams) { instance.extract_datastreams }

    let(:metadata_dir) { instance_double(Pathname) }
    let(:metadata_file) { instance_double(Pathname, exist?: false) }
    let(:metadata_string) { '<metadata/>' }

    before do
      allow(workspace).to receive(:path).with('metadata', true).and_return('metadata_dir')
      expect(Pathname).to receive(:new).with('metadata_dir').and_return(metadata_dir)
      expect(metadata_dir).to receive(:join).at_least(5).times.and_return(metadata_file)
      expect(metadata_file).to receive(:open).at_least(5).times
      allow(instance).to receive(:datastream_content).and_return(metadata_string)
    end

    it 'extracts the datastreams' do
      extract_datastreams
      expect(instance).to have_received(:datastream_content).with(:administrativeMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:contentMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:defaultObjectRights, false)
      expect(instance).to have_received(:datastream_content).with(:descMetadata, true).once
      expect(instance).to have_received(:datastream_content).with(:events, false)
      expect(instance).to have_received(:datastream_content).with(:geoMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:embargoMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:identityMetadata, true)
      expect(instance).to have_received(:datastream_content).with(:provenanceMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:relationshipMetadata, true)
      expect(instance).to have_received(:datastream_content).with(:roleMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:sourceMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:rightsMetadata, false)
      expect(instance).to have_received(:datastream_content).with(:versionMetadata, true)
      expect(instance).to have_received(:datastream_content).with(:workflows, false)
    end
  end

  describe '#datastream_content' do
    subject(:datastream_content) { instance.send(:datastream_content, ds_name, required) }

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

      let(:expected_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
            <versionMetadata objectId="druid:nc893zj8956">
              <version versionId="1" tag="1.0.0">
                <description>
                  Initial version
                </description>
              </version>
              <version versionId="2"/>
            </versionMetadata>
        XML
      end

      before do
        allow(VersionMigrationService).to receive(:migrate)
        ObjectVersion.create(druid: druid, version: 1, tag: '1.0.0', description: 'Initial version')
        ObjectVersion.create(druid: druid, version: 2)
      end

      it { is_expected.to be_equivalent_to expected_xml }
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
end
