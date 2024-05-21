# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservationMetadataExtractor do
  let(:workspace) { instance_double(DruidTools::Druid, path: 'foo') }
  let(:druid) { 'druid:nc893zj8956' }
  let(:instance) { described_class.new(workspace:, cocina_object:) }
  let(:cocina_object) { create(:repository_object, :with_repository_object_version, external_identifier: druid).to_cocina }

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
        .with(
          <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <versionMetadata objectId="druid:nc893zj8956">
              <version versionId="1">
                <description>Best version ever</description>
              </version>
            </versionMetadata>
          XML
        )
      expect(content_file).to have_received(:<<)
        .with(
          <<~XML
            <?xml version="1.0"?>
            <contentMetadata objectId="druid:nc893zj8956" type="book">
              <resource id="https://cocina.sul.stanford.edu/fileSet/nc893zj8956-123-456-789" sequence="1" type="file">
                <label>Page 1</label>
                <file id="00001.html" mimetype="text/html" size="0" publish="no" shelve="no" preserve="yes" role="transcription">
                  <checksum type="sha1">cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7</checksum>
                  <checksum type="md5">e6d52da47a5ade91ae31227b978fb023</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        )

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
