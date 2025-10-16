# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupService do
  let(:service) { described_class.new(druid:) }
  let(:fixtures) { Pathname(File.dirname(__FILE__)).join('../fixtures') }
  let(:druid) { 'druid:bb123df4567' }
  let(:workspace_root_pathname) { Pathname(Settings.cleanup.local_workspace_root) }
  let(:workitem_pathname) { Pathname(DruidTools::Druid.new(druid, workspace_root_pathname.to_s).path) }
  let(:export_pathname) { Pathname(Settings.cleanup.local_export_home) }
  let(:bag_pathname) { export_pathname.join(druid.split(':').last) }
  let(:tarfile_pathname) { export_pathname.join("#{bag_pathname}.tar") }
  # e.g. tmp/stopped/bb123df4567/workspace
  let(:workspace_backup_path) do
    Pathname(Settings.cleanup.local_backup_path).join(File.basename(workitem_pathname),
                                                      File.basename(workspace_root_pathname))
  end

  before do
    allow(described_class).to receive(:new).and_return(service)
    allow(Settings.cleanup).to receive_messages(
      local_workspace_root: fixtures.join('workspace').to_s,
      local_export_home: fixtures.join('export').to_s,
      local_assembly_root: fixtures.join('assembly').to_s,
      local_backup_path: Rails.root.join('tmp/stopped').to_s
    )
    export_pathname = Pathname(Settings.cleanup.local_export_home)
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
    workitem_pathname.rmtree if workitem_pathname.exist?
  end

  it 'can find the fixtures workspace and export folders' do
    expect(File).to be_directory(Settings.cleanup.local_workspace_root)
    expect(File).to be_directory(Settings.cleanup.local_export_home)
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

  describe '.reset_accessioning' do
    let(:initial_description) do
      {
        'title' => [{ 'value' => 'My first title' }],
        'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
      }
    end
    let(:repository_object) { create(:repository_object, external_identifier: druid) }

    before do
      # Set descriptive metadata on initial version to test metadata reversion later
      repository_object.head_version.update!(description: initial_description)
      repository_object.close_version!
      repository_object.head_version.update!(cocina_version: Cocina::Models::VERSION)
      repository_object.open_version!(description: 'draft')
      allow(service).to receive(:backup_content_by_druid)
      allow(service).to receive(:cleanup_by_druid)
      allow(service).to receive(:delete_accessioning_workflows)
    end

    context 'when object cannot be opened and preservationIngestWF exists and is completed' do
      before do
        allow(VersionService).to receive_messages(can_open?: false)
      end

      it 'discards draft, backups, cleans up content, and deletes workflows' do
        expect { described_class.reset_accessioning(druid) }.to output.to_stdout
        expect(repository_object.reload.head_version).to be_closed
        expect(service).to have_received(:backup_content_by_druid).once
        expect(service).to have_received(:cleanup_by_druid).once
        expect(service).to have_received(:delete_accessioning_workflows).once
      end

      context 'with dryrun param set to true' do
        it 'does nothing' do
          expect { described_class.reset_accessioning(druid, dryrun: true) }.to output.to_stdout
          expect(repository_object.reload.head_version).to be_open
          expect(service).not_to have_received(:backup_content_by_druid)
          expect(service).not_to have_received(:cleanup_by_druid)
          expect(service).not_to have_received(:delete_accessioning_workflows)
        end
      end
    end

    context 'when head version cannot be discarded' do
      before do
        repository_object.last_closed_version.update(cocina_version: nil)
      end

      it 'cleans up without changing repository object' do
        expect do
          described_class.reset_accessioning(druid)
        end.to output(/Head version \(2\) of object #{druid} cannot be discarded/).to_stdout
        expect(repository_object.reload.head_version).to be_open
        expect(service).to have_received(:backup_content_by_druid).once
        expect(service).to have_received(:cleanup_by_druid).once
        expect(service).to have_received(:delete_accessioning_workflows).once
      end
    end

    context 'when head version can be reopened' do
      let(:bogus_description) { { 'this' => 'does not validate and should be reverted' } }

      before do
        repository_object.head_version.update!(description: bogus_description)
        repository_object.close_version!
      end

      it 'cleans up and reopens repository object' do
        expect { described_class.reset_accessioning(druid) }.to output(/Reopening object #{druid}/).to_stdout
        expect(repository_object.reload).to be_open
        expect(repository_object.head_version.description).to eq(bogus_description)
        expect(service).to have_received(:backup_content_by_druid).once
        expect(service).to have_received(:cleanup_by_druid).once
        expect(service).to have_received(:delete_accessioning_workflows).once
      end

      context 'with revert_description param set to true' do
        it 'discards draft, backups, cleans up content, deletes workflows, and reverts descriptive metadata' do
          expect do
            described_class.reset_accessioning(druid, revert_description: true)
          end.to output(/restoring descriptive metadata from prior version: v1/).to_stdout
          expect(repository_object.reload).to be_open
          expect(repository_object.head_version.description).to eq(initial_description)
          expect(service).to have_received(:backup_content_by_druid).once
          expect(service).to have_received(:cleanup_by_druid).once
          expect(service).to have_received(:delete_accessioning_workflows).once
        end
      end
    end

    context 'when object cannot be opened and preservationIngestWF does not exist' do
      before do
        allow(VersionService).to receive_messages(can_open?: false)
      end

      it 'backups, cleans up content, and delete workflows' do
        expect { described_class.reset_accessioning(druid) }.to output.to_stdout
        expect(service).to have_received(:backup_content_by_druid).once
        expect(service).to have_received(:cleanup_by_druid).once
        expect(service).to have_received(:delete_accessioning_workflows).once
      end
    end

    context 'with bogus druid' do
      before do
        allow(described_class).to receive(:new).and_call_original
      end

      it 'raises an exception and stops' do
        expect { described_class.reset_accessioning('bogus') }.to raise_error StandardError
        expect(service).not_to have_received(:backup_content_by_druid)
        expect(service).not_to have_received(:cleanup_by_druid)
        expect(service).not_to have_received(:delete_accessioning_workflows)
      end
    end

    context 'with object not found' do
      before do
        allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      end

      it 'raises an exception and stops' do
        expect { described_class.reset_accessioning }.to raise_error StandardError
        expect(service).not_to have_received(:backup_content_by_druid)
        expect(service).not_to have_received(:cleanup_by_druid)
        expect(service).not_to have_received(:delete_accessioning_workflows)
      end
    end
  end

  describe '.backup_content_by_druid' do
    before do
      allow(service).to receive(:backup_content)
    end

    it 'calls backup_content for each workspace area' do
      described_class.backup_content_by_druid(druid)
      expect(service).to have_received(:backup_content).once.with(Settings.cleanup.local_workspace_root,
                                                                  Settings.cleanup.local_backup_path)
      expect(service).to have_received(:backup_content).once.with(Settings.cleanup.local_assembly_root,
                                                                  Settings.cleanup.local_backup_path)
      expect(service).to have_received(:backup_content).once.with(Settings.cleanup.local_export_home,
                                                                  Settings.cleanup.local_backup_path)
    end
  end

  describe '.delete_accessioning_workflows' do
    let(:version) { 1 }

    before do
      allow(Workflow::Service).to receive(:delete)
    end

    it 'calls workflow client to delete each accessioning workflow' do
      described_class.delete_accessioning_workflows(druid, version)
      expect(Workflow::Service).to have_received(:delete).once.with(druid:, workflow_name: 'accessionWF', version:)
      expect(Workflow::Service).to have_received(:delete).once.with(druid:, workflow_name: 'assemblyWF', version:)
      expect(Workflow::Service).to have_received(:delete).once.with(druid:, workflow_name: 'versioningWF', version:)
    end
  end

  describe '.cleanup_export' do
    before do
      allow(FileUtils).to receive(:rm_rf).and_call_original
      allow(FileUtils).to receive(:rm_f).and_call_original
    end

    it 'removes the files exported to preservation' do
      service.send(:cleanup_export)
      expect(FileUtils).to have_received(:rm_rf).once.with(fixtures.join('export/bb123df4567').to_s)
      expect(FileUtils).to have_received(:rm_f).once.with(fixtures.join('export/bb123df4567.tar').to_s)
    end
  end

  describe '.backup_content' do
    it 'backs up and then removes content from workspace area' do
      expect(workspace_backup_path.join('content')).not_to exist # backup content is not there yet
      expect(workitem_pathname.join('content')).to exist
      service.send(:backup_content, workspace_root_pathname, Settings.cleanup.local_backup_path)
      expect(workitem_pathname.join('content')).to exist # main content is still there!
      expect(workspace_backup_path.join('content')).to exist # backup content is now there
    end
  end

  context 'with real files' do
    let(:fixture_dir) { '/tmp/cleanup-spec' }
    let(:workspace_dir) { File.join(fixture_dir, 'workspace') }
    let(:export_dir) { File.join(fixture_dir, 'export') }
    let(:assembly_dir) { File.join(fixture_dir, 'assembly') }
    let(:staging_dir) { File.join(fixture_dir, 'staging') }

    let(:druid1) { 'druid:cd456ef7890' }
    let(:druid2) { 'druid:cd456gh1234' }

    before do
      allow(described_class).to receive(:new).and_call_original
      allow(Settings.cleanup).to receive_messages(
        local_workspace_root: workspace_dir,
        local_export_home: export_dir,
        local_assembly_root: assembly_dir,
        local_staging_root: staging_dir
      )

      FileUtils.mkdir_p fixture_dir
      FileUtils.mkdir_p workspace_dir
      FileUtils.mkdir_p export_dir
      FileUtils.mkdir_p assembly_dir
      FileUtils.mkdir_p staging_dir
    end

    def create_tempfile(path)
      File.write(File.join(path, 'tempfile'), 'junk')
    end

    it 'correctly prunes directories' do
      dr1_wspace = DruidTools::Druid.new(druid1, workspace_dir)
      dr2_wspace = DruidTools::Druid.new(druid2, workspace_dir)
      dr1_assembly = DruidTools::Druid.new(druid1, assembly_dir)
      dr2_assembly = DruidTools::Druid.new(druid2, assembly_dir)
      dr1_staging = DruidTools::Druid.new(druid1, staging_dir)
      dr2_staging = DruidTools::Druid.new(druid2, staging_dir)

      dr1_wspace.mkdir
      dr2_wspace.mkdir
      dr1_assembly.mkdir
      dr2_assembly.mkdir
      dr1_staging.mkdir
      dr2_staging.mkdir

      # Add some 'content'
      create_tempfile dr1_wspace.path
      create_tempfile dr2_assembly.path
      create_tempfile dr1_staging.path

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
      expect(File).to exist(dr1_staging.path)

      # druid1 cleaned up, including files
      described_class.cleanup_by_druid druid1
      expect(File).not_to exist(dr1_wspace.path)
      expect(File).not_to exist(dr1_assembly.path)
      expect(File).not_to exist(dr1_staging.path)
      expect(File).not_to exist(export_prefix)
      expect(File).not_to exist("#{export_prefix}.tar")

      # But not druid2
      expect(File).to exist(dr2_wspace.path)
      expect(File).to exist(dr2_assembly.path)
      expect(File).to exist(dr2_staging.path)
      expect(File).to exist(File.join(assembly_dir, 'cd'))

      described_class.cleanup_by_druid druid2
      expect(File).not_to exist(dr2_wspace.path)
      expect(File).not_to exist(dr2_assembly.path)
      expect(File).not_to exist(dr2_staging.path)

      # Empty common parent directories pruned
      expect(File).not_to exist(File.join(workspace_dir, 'cd'))
      expect(File).not_to exist(File.join(assembly_dir, 'cd'))
    end

    it 'cleans up without assembly or staging content' do
      dr1_wspace = DruidTools::Druid.new(druid1, workspace_dir)
      dr1_wspace.mkdir

      described_class.cleanup_by_druid druid1
      expect(File).not_to exist(dr1_wspace.path)
    end
  end
end
