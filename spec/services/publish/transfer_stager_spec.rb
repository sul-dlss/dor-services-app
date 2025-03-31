# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::TransferStager do
  describe '.copy' do
    let(:stager) do
      described_class.new(druid:, filepath_map:, workspace_content_pathname: Pathname.new(workspace_content_path))
    end

    let(:druid) { 'druid:bc123df4567' }
    let(:filepath_map) { { 'file1.txt' => 'uuid1', 'files/file2.txt' => 'uuid2', 'file3.txt' => 'uuid3' } }

    let(:transfer_stage_root) { 'tmp/transfer_staging' }
    let(:workspace_root) { 'tmp/workspace' }
    let(:workspace_content_path) { "#{workspace_root}/bc/123/df/4567/bc123df4567/content" }

    before do
      allow(Settings.stacks).to receive_messages(transfer_stage_root:, local_workspace_root: workspace_root)
      Settings.stacks.local_workspace_root
      FileUtils.mkdir_p(transfer_stage_root)
      File.write("#{transfer_stage_root}/uuid3", 'existing')

      FileUtils.mkdir_p("#{workspace_content_path}/files")
      File.write("#{workspace_content_path}/file1.txt", 'file1.txt')
      File.write("#{workspace_content_path}/files/file2.txt", 'file2.txt')
      File.write("#{workspace_content_path}/file3.txt", 'file3.txt')
    end

    after do
      FileUtils.rm_rf(transfer_stage_root)
    end

    it 'copies files to the transfer staging area' do
      stager.copy
      expect(File.read("#{transfer_stage_root}/uuid1")).to eq('file1.txt')
      expect(File.read("#{transfer_stage_root}/uuid2")).to eq('file2.txt')
      expect(File.read("#{transfer_stage_root}/uuid3")).to eq('existing')
    end
  end
end
