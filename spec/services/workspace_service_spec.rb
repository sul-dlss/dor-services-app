# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkspaceService do
  describe '.create' do
    before do
      FileUtils.rm_rf(temp_workspace)
      allow(Settings.stacks).to receive(:local_workspace_root).and_return(temp_workspace)

      FileUtils.mkdir_p(temp_workspace)
      FileUtils.rm_rf(File.join(temp_workspace, 'aa'))
    end

    after do
      FileUtils.rm_rf(temp_workspace)
    end

    let(:temp_workspace) { '/tmp/dor_ws' }
    let(:druid_path) { File.join(temp_workspace, 'mx', '123', 'qw', '2323', 'mx123qw2323') }
    let(:work) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:mx123qw2323') }

    it 'creates a plain directory in the workspace when passed no source directory' do
      described_class.create(work, nil)
      expect(File).to be_directory(druid_path)
      expect(File).not_to be_symlink(druid_path)
    end

    it 'creates a link in the workspace to a passed in source directory' do
      source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(source_dir)
      described_class.create(work, source_dir)

      expect(File).to be_symlink(druid_path)
      expect(File.readlink(druid_path)).to eq(source_dir)
    end
  end

  describe '.mkdir_with_final_link' do
    let(:strictly_valid_druid_str) { 'druid:mx123qw2323' }
    let(:tree) { File.join(fixture_dir, 'mx/123/qw/2323/mx123qw2323') }
    let(:source_dir) { '/tmp/content_dir' }
    let(:druid_obj) { DruidTools::Druid.new(strictly_valid_druid_str, fixture_dir) }

    before do
      FileUtils.mkdir_p(source_dir)
    end

    after do
      FileUtils.rm_rf(File.join(fixture_dir, 'mx'))
    end

    it 'creates a druid tree in the workspace with the final directory being a link to the passed in source' do
      described_class.send(:mkdir_with_final_link, druid: druid_obj, source: source_dir)
      expect(File).to be_symlink(druid_obj.path)
      expect(File.readlink(tree)).to eq(source_dir)
    end

    it 'raises DifferentContentExistsError if a directory already exists in the workspace for this druid' do
      druid_obj.mkdir(fixture_dir)
      expect do
        described_class.send(:mkdir_with_final_link, druid: druid_obj,
                                                     source: source_dir)
      end.to raise_error(DruidTools::DifferentContentExistsError)
    end
  end
end
