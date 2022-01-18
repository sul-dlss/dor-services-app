# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe Preserve::FileInventoryBuilder do
  let(:fixtures) { Pathname(File.dirname(__FILE__)).join('../../fixtures') }
  let(:export_dir) { Pathname(Settings.sdr.local_export_home) }
  let(:fixture_sig_cat_obj) do
    Moab::SignatureCatalog.parse(
      File.read(fixtures.join('sdr_repo/dd116zh0343/v0001/manifests/signatureCatalog.xml'))
    )
  end

  before do
    allow(Settings.sdr).to receive_messages(local_workspace_root: fixtures.join('workspace').to_s,
                                            local_export_home: fixtures.join('export').to_s)

    export_dir.rmtree if export_dir.exist? && export_dir.basename.to_s == 'export'
    export_dir.mkdir
  end

  after do
    export_dir.rmtree if export_dir.exist? && export_dir.basename.to_s == 'export'
  end

  describe '.build' do
    subject(:result) do
      described_class.build(metadata_dir: metadata_dir, druid: druid, version_id: version_id)
    end

    let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata') }
    let(:druid) { 'druid:ab123cd4567' }
    let(:version_id) { 2 }

    it 'creates a file inventory' do
      expect(result).to be_instance_of Moab::FileInventory
      expect(result.groups.size).to eq 2
    end
  end

  describe '#content_inventory' do
    subject(:version_inventory) { instance.content_inventory }

    let(:druid) { 'druid:ab123cd4567' }
    let(:version_id) { 2 }

    let(:instance) do
      described_class.new(metadata_dir: metadata_dir, druid: druid, version_id: version_id)
    end

    context 'when contentMetadata.xml exists' do
      let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata') }

      it 'builds the inventory from contentMetadata' do
        expect(version_inventory).to be_instance_of Moab::FileInventory
        expect(version_inventory.version_id).to eq 2
        content_group = version_inventory.groups[0]
        expect(content_group.group_id).to eq 'content'
        expect(content_group.files.size).to eq 2
        # files in the 2nd resource are copied from the first resource
        expect(content_group.files[0].instances.size).to eq 2
      end
    end

    context "when contentMetadata.xml doesn't exist" do
      let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567') }

      it 'has no groups' do
        expect(version_inventory.groups.size).to eq 0
      end
    end
  end

  describe '#content_metadata' do
    subject(:content_metadata) { instance.content_metadata }

    let(:druid) { 'druid:ab123cd4567' }
    let(:version_id) { 2 }

    let(:instance) do
      described_class.new(metadata_dir: metadata_dir, druid: druid, version_id: version_id)
    end

    context 'when contentMetadata.xml exists' do
      let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata') }

      it { is_expected.to match(/<contentMetadata /) }
    end

    context "when contentMetadata.xml doesn't exist" do
      let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567') }

      it { is_expected.to be_nil }
    end
  end

  describe '#metadata_file_group' do
    let(:druid) { 'druid:ab123cd4567' }
    let(:version_id) { 2 }
    let(:metadata_dir) { fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata') }

    let(:instance) do
      described_class.new(metadata_dir: metadata_dir, druid: druid, version_id: version_id)
    end

    let(:file_group) { instance_double(Moab::FileGroup, group_from_directory: nil) }

    before do
      allow(Moab::FileGroup).to receive(:new).and_return(file_group)
    end

    it 'initializes the file group' do
      instance.metadata_file_group
      expect(Moab::FileGroup).to have_received(:new).with(group_id: 'metadata')
      expect(file_group).to have_received(:group_from_directory).with(metadata_dir)
    end
  end
end
