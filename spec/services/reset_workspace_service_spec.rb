# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetWorkspaceService do
  let(:workspace_root) { Dor::Config.stacks.local_workspace_root }
  let(:export_root) { Settings.sdr.local_export_home }
  let(:export_pathname) { Pathname(export_root) }

  before do
    allow(Dor::Config.stacks).to receive(:local_workspace_root).and_return(File.join(fixture_dir, 'workspace'))
    allow(Settings.sdr).to receive(:local_export_home).and_return(File.join(fixture_dir, 'export'))
  end

  describe '.reset_workspace_druid_tree' do
    let(:druid) { 'druid:am111am1111' }
    let(:druid_tree_path) { "#{workspace_root}/am/111/am/1111/am111am1111" }
    let(:archived_druid_tree_path) { "#{workspace_root}/vr/111/vr/1111/vr111vr1111" }
    let(:archived_druid) { 'druid:vr111vr1111' }

    before do
      # To make sure the directory name is as expected am111am1111

      FileUtils.mv(druid_tree_path + '_v2', druid_tree_path) if File.exist?(druid_tree_path + '_v2')
    end

    after do
      # To reset the environment to its original format
      FileUtils.mv(druid_tree_path + '_v2', druid_tree_path) if File.exist?(druid_tree_path + '_v2')
      FileUtils.mv("#{archived_druid_tree_path}_v3", archived_druid_tree_path) if File.exist?(archived_druid_tree_path + '_v3')
    end

    it 'renames the directory tree with the directory not empty' do
      described_class.reset_workspace_druid_tree(druid: druid, version: '2', workspace_root: workspace_root)
      expect(File).to exist("#{druid_tree_path}_v2")
      expect(File).not_to exist(druid_tree_path)
    end

    it 'does nothing with truncated druid' do
      truncated_druid = 'druid:tr111tr1111'
      described_class.reset_workspace_druid_tree(druid: truncated_druid, version: '2', workspace_root: workspace_root)
      truncated_druid_tree_path = "#{workspace_root}/tr/111/tr/1111/"
      expect(File).not_to exist("#{truncated_druid_tree_path}_v2")
      expect(File).to exist(truncated_druid_tree_path)
    end

    it 'throws an error if the directory is already archived' do
      expect { described_class.reset_workspace_druid_tree(druid: archived_druid, version: '2', workspace_root: workspace_root) }
        .to raise_error(ResetWorkspaceService::DirectoryAlreadyExists)
    end

    it "archiveds the current directory even if there is an older archived that hasn't been cleaned up" do
      described_class.reset_workspace_druid_tree(druid: archived_druid, version: '3', workspace_root: workspace_root)
      expect(File).to exist("#{archived_druid_tree_path}_v2")
      expect(File).to exist("#{archived_druid_tree_path}_v3")
      expect(File).not_to exist(archived_druid_tree_path.to_s)
    end
  end

  describe '.remove_export_bag' do
    let(:druid) { "druid:#{id}" }
    let(:id) { 'zb871zd0767' }
    let(:bag_path) { "#{export_root}/#{id}" }

    before do
      create_bag_dir(id)
      create_bag_tar(id)
    end

    it 'removes the export bags directory and tar files' do
      expect do
        described_class.remove_export_bag(druid: druid, export_root: export_root)
      end.to change { File.exist?(bag_path.to_s) }.from(true).to(false).and change { File.exist?("#{bag_path}.tar") }.from(true).to(false)
    end
  end

  def create_bag_tar(file_name)
    tarfile_pathname = export_pathname.join(file_name + '.tar')
    tarfile_pathname.open('w') { |file| file.write("test tar\n") }
  end

  def create_bag_dir(bag_name)
    bag_pathname = Pathname(export_pathname.join(bag_name))
    bag_pathname.mkpath
    bag_pathname.join('content').mkpath
    bag_pathname.join('temp').mkpath
  end
end
