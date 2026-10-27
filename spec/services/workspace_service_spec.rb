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
    let(:druid) { 'druid:mx123qw2323' }

    it 'creates a plain directory in the workspace' do
      result = described_class.create(druid)
      expect(File).to be_directory(druid_path)
      expect(File).not_to be_symlink(druid_path)
      expect(result).to eq(druid_path)
      expect(File).not_to be_directory(File.join(druid_path, 'content'))
      expect(File).not_to be_directory(File.join(druid_path, 'metadata'))
    end

    it 'creates a plain directory with content subfolder in the workspace' do
      result = described_class.create(druid, content: true)
      expect(File).to be_directory(druid_path)
      expect(File).not_to be_symlink(druid_path)
      expect(result).to eq(druid_path)
      expect(File).to be_directory(File.join(druid_path, 'content'))
      expect(File).not_to be_directory(File.join(druid_path, 'metadata'))
    end

    it 'creates a plain directory with metadata subfolder in the workspace' do
      result = described_class.create(druid, metadata: true)
      expect(File).to be_directory(druid_path)
      expect(File).not_to be_symlink(druid_path)
      expect(result).to eq(druid_path)
      expect(File).not_to be_directory(File.join(druid_path, 'content'))
      expect(File).to be_directory(File.join(druid_path, 'metadata'))
    end
  end
end
