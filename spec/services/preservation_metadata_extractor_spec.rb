# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservationMetadataExtractor do
  let(:workspace) { instance_double(DruidTools::Druid, path: 'foo') }
  let(:druid) { 'druid:nc893zj8956' }
  let(:instance) { described_class.new(workspace: workspace, cocina_object: cocina_object) }
  let(:cocina_object) { build(:dro, id: druid) }

  describe '.extract' do
    subject(:extract) { instance.extract }

    let(:metadata_dir) { instance_double(Pathname) }
    let(:version_path) { instance_double(Pathname, exist?: false, open: true) }
    let(:content_path) { instance_double(Pathname, exist?: false, open: true) }
    let(:version_file) { instance_double(File, :<< => nil) }
    let(:content_file) { instance_double(File, :<< => nil) }

    before do
      allow(workspace).to receive(:path).with('metadata', true).and_return('metadata_dir')
      expect(Pathname).to receive(:new).with('metadata_dir').and_return(metadata_dir)
      allow(Pathname).to receive(:new).and_call_original
      allow(metadata_dir).to receive(:join).with('versionMetadata.xml').and_return(version_path)
      allow(metadata_dir).to receive(:join).with('contentMetadata.xml').and_return(content_path)

      allow(instance).to receive(:extract_cocina)
      allow(version_path).to receive(:open).and_yield(version_file)
      allow(content_path).to receive(:open).and_yield(content_file)
    end

    it 'extracts the metadata' do
      extract
      expect(version_file).to have_received(:<<)
        .with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<versionMetadata objectId=\"druid:nc893zj8956\"/>\n")
      expect(content_file).to have_received(:<<)
        .with("<?xml version=\"1.0\"?>\n<contentMetadata objectId=\"druid:nc893zj8956\" type=\"file\"/>\n")

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

    it 'serializes json' do
      instance.send(:extract_cocina)
      expect(metadata_dir).to have_received(:join).with('cocina.json')
      expect(file).to have_received(:<<)
        .with(/"cocinaVersion":/)
    end
  end
end
