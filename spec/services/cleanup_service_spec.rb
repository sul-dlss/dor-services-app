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
  let(:workspace_backup_path) { Pathname(Settings.cleanup.local_backup_path).join(File.basename(workitem_pathname), File.basename(workspace_root_pathname)) } # e.g. tmp/stopped/aa123bb4567/workspace

  before do
    allow(Settings.cleanup).to receive_messages(
      local_workspace_root: fixtures.join('workspace').to_s,
      local_export_home: fixtures.join('export').to_s,
      local_assembly_root: fixtures.join('assembly').to_s,
      local_backup_path: Rails.root.join('tmp/stopped').to_s
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
    workspace_backup_path.rmtree if workspace_backup_path.exist?
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

  describe '.stop_accessioning' do
    let(:dro) { build(:ar_dro) }
    let(:druid) { dro.external_identifier }
    let(:version) { dro.version }
    let(:client) { instance_double(Dor::Workflow::Client) }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(dro)
      allow(described_class).to receive(:backup_content_by_druid)
      allow(described_class).to receive(:cleanup_by_druid)
      allow(described_class).to receive(:delete_accessioning_workflows)
    end

    context 'when object cannot be opened and preservationIngestWF exists and is completed' do
      before do
        allow(VersionService).to receive_messages(can_open?: false)
        allow(WorkflowClientFactory).to receive(:build).and_return(client)
        allow(client).to receive(:workflow_status).with(druid:, workflow: 'preservationIngestWF', process: 'complete-ingest').and_return('completed')
      end

      it 'backups, cleans up content, and delete workflows' do
        described_class.stop_accessioning(druid)
        expect(described_class).to have_received(:backup_content_by_druid).once.with(druid)
        expect(described_class).to have_received(:cleanup_by_druid).once.with(druid)
        expect(described_class).to have_received(:delete_accessioning_workflows).once.with(druid, version)
      end

      context 'when dryrun' do
        it 'does nothing' do
          described_class.stop_accessioning(druid, dryrun: true)
          expect(described_class).not_to have_received(:backup_content_by_druid)
          expect(described_class).not_to have_received(:cleanup_by_druid)
          expect(described_class).not_to have_received(:delete_accessioning_workflows)
        end
      end
    end

    context 'when object cannot be opened and preservationIngestWF does not exist' do
      before do
        allow(VersionService).to receive_messages(can_open?: false)
        allow(WorkflowClientFactory).to receive(:build).and_return(client)
        allow(client).to receive(:workflow_status).with(druid:, workflow: 'preservationIngestWF', process: 'complete-ingest').and_return(nil)
      end

      it 'backups, cleans up content, and delete workflows' do
        described_class.stop_accessioning(druid)
        expect(described_class).to have_received(:backup_content_by_druid).once.with(druid)
        expect(described_class).to have_received(:cleanup_by_druid).once.with(druid)
        expect(described_class).to have_received(:delete_accessioning_workflows).once.with(druid, version)
      end
    end

    context 'when object can be opened (i.e. already in perservation)' do
      before { allow(VersionService).to receive_messages(can_open?: true) }

      it 'raises an exception and stops' do
        expect { described_class.stop_accessioning(druid) }.to raise_error StandardError
        expect(described_class).not_to have_received(:backup_content_by_druid)
        expect(described_class).not_to have_received(:cleanup_by_druid)
        expect(described_class).not_to have_received(:delete_accessioning_workflows)
      end
    end

    context 'when object cannot be opened but preservationIngestWF exists and is not complete (i.e. problem preserving)' do
      before do
        allow(VersionService).to receive_messages(can_open?: false)
        allow(WorkflowClientFactory).to receive(:build).and_return(client)
        allow(client).to receive(:workflow_status).with(druid:, workflow: 'preservationIngestWF', process: 'complete-ingest').and_return('waiting')
      end

      it 'raises an exception and stops' do
        expect { described_class.stop_accessioning(druid) }.to raise_error StandardError
        expect(described_class).not_to have_received(:backup_content_by_druid)
        expect(described_class).not_to have_received(:cleanup_by_druid)
        expect(described_class).not_to have_received(:delete_accessioning_workflows)
      end
    end

    context 'with bogus druid' do
      it 'raises an exception and stops' do
        expect { described_class.stop_accessioning('bogus') }.to raise_error StandardError
        expect(described_class).not_to have_received(:backup_content_by_druid)
        expect(described_class).not_to have_received(:cleanup_by_druid)
        expect(described_class).not_to have_received(:delete_accessioning_workflows)
      end
    end

    context 'with object not found' do
      before do
        allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      end

      it 'raises an exception and stops' do
        expect { described_class.stop_accessioning('druid:oo001oo0001') }.to raise_error StandardError
        expect(described_class).not_to have_received(:backup_content_by_druid)
        expect(described_class).not_to have_received(:cleanup_by_druid)
        expect(described_class).not_to have_received(:delete_accessioning_workflows)
      end
    end
  end

  describe '.backup_content_by_druid' do
    before do
      allow(described_class).to receive(:backup_content)
    end

    it 'calls backup_content for each workspace area' do
      described_class.backup_content_by_druid(druid)
      expect(described_class).to have_received(:backup_content).once.with(druid, Settings.cleanup.local_workspace_root, Settings.cleanup.local_backup_path)
      expect(described_class).to have_received(:backup_content).once.with(druid, Settings.cleanup.local_assembly_root, Settings.cleanup.local_backup_path)
      expect(described_class).to have_received(:backup_content).once.with(druid, Settings.cleanup.local_export_home, Settings.cleanup.local_backup_path)
    end
  end

  describe '.delete_accessioning_workflows' do
    let(:client) { instance_double(Dor::Workflow::Client, delete_workflow: nil) }
    let(:version) { 1 }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(client)
    end

    it 'calls workflow client to delete each accessioning workflow' do
      described_class.delete_accessioning_workflows(druid, version)
      expect(client).to have_received(:delete_workflow).once.with(druid:, workflow: 'accessionWF', version:)
      expect(client).to have_received(:delete_workflow).once.with(druid:, workflow: 'assemblyWF', version:)
      expect(client).to have_received(:delete_workflow).once.with(druid:, workflow: 'versioningWF', version:)
    end
  end

  describe '.cleanup_export' do
    before do
      allow(FileUtils).to receive(:rm_rf)
      allow(FileUtils).to receive(:rm_f)
    end

    it 'removes the files exported to preservation' do
      described_class.send(:cleanup_export, druid)
      expect(FileUtils).to have_received(:rm_rf).once.with(fixtures.join('export/aa123bb4567').to_s)
      expect(FileUtils).to have_received(:rm_f).once.with(fixtures.join('export/aa123bb4567.tar').to_s)
    end
  end

  describe '.backup_content' do
    it 'backs up and then removes content from workspace area' do
      expect(workspace_backup_path.join('content')).not_to exist # backup content is not there yet
      expect(workitem_pathname.join('content')).to exist
      described_class.send(:backup_content, druid, workspace_root_pathname, Settings.cleanup.local_backup_path)
      expect(workitem_pathname.join('content')).to exist # main content is still there!
      expect(workspace_backup_path.join('content')).to exist # backup content is now there
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

    let(:druid1) { 'druid:cd456ef7890' }
    let(:druid2) { 'druid:cd456gh1234' }

    before do
      allow(Settings.cleanup).to receive_messages(
        local_workspace_root: workspace_dir,
        local_export_home: export_dir,
        local_assembly_root: assembly_dir
      )
      allow(Settings.stacks).to receive(:local_stacks_root).and_return(stacks_dir)

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
        dr1_wspace = DruidTools::Druid.new(druid1, workspace_dir)
        dr2_wspace = DruidTools::Druid.new(druid2, workspace_dir)
        dr1_assembly = DruidTools::Druid.new(druid1, assembly_dir)
        dr2_assembly = DruidTools::Druid.new(druid2, assembly_dir)

        dr1_wspace.mkdir
        dr2_wspace.mkdir
        dr1_assembly.mkdir
        dr2_assembly.mkdir

        # Add some 'content'
        create_tempfile dr1_wspace.path
        create_tempfile dr2_assembly.path

        # Setup the export content, remove 'druid:' prefix for bag and export/workspace dir
        dr1 = druid1.split(':').last
        export_prefix = File.join(export_dir, dr1)

        # Create {export_dir}/druid1
        #        {export_dir}/druid1/tempfile
        #        {export_dir}/druid1.tar
        FileUtils.mkdir export_prefix
        create_tempfile export_prefix
        File.write("#{export_prefix}.tar", 'fake tar junk')

        expect(File).to exist(dr1_wspace.path)
        expect(File).to exist(dr1_assembly.path)

        # druid1 cleaned up, including files
        described_class.cleanup_by_druid druid1
        expect(File).not_to exist(dr1_wspace.path)
        expect(File).not_to exist(dr1_assembly.path)
        expect(File).not_to exist(export_prefix)
        expect(File).not_to exist("#{export_prefix}.tar")

        # But not druid2
        expect(File).to exist(dr2_wspace.path)
        expect(File).to exist(dr2_assembly.path)

        described_class.cleanup_by_druid druid2
        expect(File).not_to exist(dr2_wspace.path)
        expect(File).not_to exist(dr2_assembly.path)

        # Empty common parent directories pruned
        expect(File).not_to exist(File.join(workspace_dir, 'cd'))
      end

      it 'cleans up without assembly content' do
        dr1_wspace = DruidTools::Druid.new(druid1, workspace_dir)
        dr1_wspace.mkdir

        described_class.cleanup_by_druid druid1
        expect(File).not_to exist(dr1_wspace.path)
      end
    end
  end
end
