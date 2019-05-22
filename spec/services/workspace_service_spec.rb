# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkspaceService do
  let(:temp_workspace) { '/tmp/dor_ws' }

  before do
    FileUtils.rm_rf(temp_workspace)

    Dor::Config.push! do |config|
      config.suri.mint_ids false
      config.solr.url 'http://solr.edu/solrizer'
      config.fedora.url 'http://fedora.edu'
    end

    allow(Settings.stacks).to receive(:local_workspace_root).and_return(temp_workspace)

    FileUtils.mkdir_p(temp_workspace)
  end

  after do
    Dor::Config.pop!
    FileUtils.rm_rf(temp_workspace)
  end

  describe '.create' do
    let(:druid_path) { File.join(temp_workspace, 'aa', '123', 'bb', '7890', 'aa123bb7890') }
    let(:work) { Dor::Item.new(pid: 'druid:aa123bb7890') }

    before do
      FileUtils.rm_rf(File.join(temp_workspace, 'aa'))
    end

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
end
