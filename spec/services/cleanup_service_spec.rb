# frozen_string_literal: true

require 'rails_helper'
# require 'pathname'
# require 'druid-tools'

RSpec.describe CleanupService do
  attr_reader :fixture_dir

  let(:fixtures) { Pathname(File.dirname(__FILE__)).join('../fixtures') }
  let(:druid) { 'druid:aa123bb4567' }
  let(:workspace_root_pathname) { Pathname(Settings.cleanup.local_workspace_root) }
  let(:workitem_pathname) { Pathname(DruidTools::Druid.new(druid, workspace_root_pathname.to_s).path) }
  let(:export_pathname) { Pathname(Settings.cleanup.local_export_home) }
  let(:bag_pathname) { export_pathname.join(druid.split(':').last) }
  let(:tarfile_pathname) { export_pathname.join("#{bag_pathname}.tar") }

  before do
    allow(Settings.cleanup).to receive_messages(
      local_workspace_root: fixtures.join('workspace').to_s,
      local_export_home: fixtures.join('export').to_s,
      local_assembly_root: fixtures.join('assembly').to_s
    )
    workitem_pathname.rmtree if workitem_pathname.exist?
    export_pathname = Pathname(Settings.cleanup.local_export_home)
    export_pathname.rmtree if export_pathname.exist?
    bag_pathname = export_pathname.join(druid.split(':').last)
    tarfile_pathname = export_pathname.join("#{bag_pathname}.tar")

    workitem_pathname.join('content').mkpath
    workitem_pathname.join('temp').mkpath
    bag_pathname.mkpath
    tarfile_pathname.open('w') { |file| file.write("test tar\n") }
  end

  after do
    item_root_branch = workspace_root_pathname.join('aa')
    item_root_branch.rmtree if item_root_branch.exist?
    bag_pathname.rmtree     if bag_pathname.exist?
    tarfile_pathname.rmtree if tarfile_pathname.exist?
  end

  it 'can find the fixtures workspace and export folders' do
    expect(File).to be_directory(Settings.cleanup.local_workspace_root)
    expect(File).to be_directory(Settings.cleanup.local_export_home)
  end

  describe '.cleanup_by_druid' do
    before do
      allow(described_class).to receive(:cleanup_export)
    end

    it 'calls cleanup_export' do
      described_class.cleanup_by_druid(druid)
      expect(described_class).to have_received(:cleanup_export).once.with(druid)
    end
  end

  describe '.cleanup_export' do
    before do
      allow(described_class).to receive(:remove_branch)
    end

    it 'removes the files exported to preservation' do
      described_class.send(:cleanup_export, druid)
      expect(described_class).to have_received(:remove_branch).once.with(fixtures.join('export/aa123bb4567').to_s)
      expect(described_class).to have_received(:remove_branch).once.with(fixtures.join('export/aa123bb4567.tar').to_s)
    end
  end

  describe '.remove_branch' do
    context 'with a non-existing branch' do
      before do
        bag_pathname.rmtree if bag_pathname.exist?
        allow(bag_pathname).to receive(:rmtree)
      end

      it "doesn't remove the tree" do
        described_class.send(:remove_branch, bag_pathname)
        expect(bag_pathname).not_to have_received(:rmtree)
      end
    end

    context 'with an existing branch' do
      before do
        bag_pathname.mkpath
        allow(bag_pathname).to receive(:rmtree)
      end

      it 'removes the tree' do
        described_class.send(:remove_branch, bag_pathname)
        expect(bag_pathname).to have_received(:rmtree)
      end
    end
  end

  describe '.cleanup_by_druid' do
    it 'can do a complete cleanup' do
      expect(workitem_pathname.join('content')).to exist
      expect(bag_pathname).to exist
      expect(tarfile_pathname).to exist
      described_class.cleanup_by_druid(druid)
      expect(workitem_pathname.parent.parent.parent.parent).not_to exist
      expect(bag_pathname).not_to exist
      expect(tarfile_pathname).not_to exist
    end
  end

  context 'with real files' do
    let(:fixture_dir) { '/tmp/cleanup-spec' }
    let(:workspace_dir) { File.join(fixture_dir, 'workspace') }
    let(:export_dir) { File.join(fixture_dir, 'export') }
    let(:assembly_dir) { File.join(fixture_dir, 'assembly') }
    let(:stacks_dir) { File.join(fixture_dir, 'stacks') }

    let(:druid_1) { 'druid:cd456ef7890' }
    let(:druid_2) { 'druid:cd456gh1234' }

    before do
      allow(Settings.cleanup).to receive_messages(
        local_workspace_root: workspace_dir,
        local_export_home: export_dir,
        local_assembly_root: assembly_dir
      )
      allow(Dor::Config.stacks).to receive(:local_stacks_root).and_return(stacks_dir)

      FileUtils.mkdir fixture_dir
      FileUtils.mkdir workspace_dir
      FileUtils.mkdir export_dir
      FileUtils.mkdir assembly_dir
      FileUtils.mkdir stacks_dir
    end

    after do
      FileUtils.rm_rf fixture_dir
    end

    def create_tempfile(path)
      File.write(File.join(path, 'tempfile'), 'junk')
    end

    describe '.cleanup_by_druid' do
      it 'correctly prunes directories' do
        dr1_wspace = DruidTools::Druid.new(druid_1, workspace_dir)
        dr2_wspace = DruidTools::Druid.new(druid_2, workspace_dir)
        dr1_assembly = DruidTools::Druid.new(druid_1, assembly_dir)
        dr2_assembly = DruidTools::Druid.new(druid_2, assembly_dir)

        dr1_wspace.mkdir
        dr2_wspace.mkdir
        dr1_assembly.mkdir
        dr2_assembly.mkdir

        # Add some 'content'
        create_tempfile dr1_wspace.path
        create_tempfile dr2_assembly.path

        # Setup the export content, remove 'druid:' prefix for bag and export/workspace dir
        dr1 = druid_1.split(':').last
        export_prefix = File.join(export_dir, dr1)

        # Create {export_dir}/druid1
        #        {export_dir}/druid1/tempfile
        #        {export_dir}/druid1.tar
        FileUtils.mkdir export_prefix
        create_tempfile export_prefix
        File.write("#{export_prefix}.tar", 'fake tar junk')

        expect(File).to exist(dr1_wspace.path)
        expect(File).to exist(dr1_assembly.path)

        # druid_1 cleaned up, including files
        described_class.cleanup_by_druid druid_1
        expect(File).not_to exist(dr1_wspace.path)
        expect(File).not_to exist(dr1_assembly.path)
        expect(File).not_to exist(export_prefix)
        expect(File).not_to exist("#{export_prefix}.tar")

        # But not druid_2
        expect(File).to exist(dr2_wspace.path)
        expect(File).to exist(dr2_assembly.path)

        described_class.cleanup_by_druid druid_2
        expect(File).not_to exist(dr2_wspace.path)
        expect(File).not_to exist(dr2_assembly.path)

        # Empty common parent directories pruned
        expect(File).not_to exist(File.join(workspace_dir, 'cd'))
      end

      it 'cleans up without assembly content' do
        dr1_wspace = DruidTools::Druid.new(druid_1, workspace_dir)
        dr1_wspace.mkdir

        described_class.cleanup_by_druid druid_1
        expect(File).not_to exist(dr1_wspace.path)
      end
    end
  end
end
