# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvableFilesStager do
  subject(:stage) { described_class.stage(druid:, workspace_content_pathname: content_dir, version: 2, filepaths:) }

  let(:workspace_root) { Dir.mktmpdir }
  let(:druid) { 'druid:jq937jp0017' }
  let(:workspace_druid) { DruidTools::Druid.new(druid, workspace_root) }

  # create an empty workspace location for object content files
  let(:content_dir) { Pathname(workspace_druid.path('content', true)) }

  let(:filepaths) { ['file1.txt', 'dir/file2.txt'] }

  before do
    allow(Preservation::Client.objects).to receive(:content)
  end

  context 'when the content files are in the workspace area' do
    before do
      # put the content files in the content_pathname location .../ng/782/rw/8378/ng782rw8378/content
      # deltas = shelve_diff.file_deltas
      # filelist = deltas[:modified] + deltas[:added] + deltas[:copyadded].collect { |_old, new| new }
      filepaths.each do |filepath|
        path = content_dir.join(filepath)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
      end
    end

    it 'does not retrieve any files from preservation' do
      stage
      expect(Preservation::Client.objects).not_to have_received(:content)
    end
  end

  context 'when the content files are not in the workspace area' do
    it 'retrieve files from preservation' do
      stage
      expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'file1.txt', version: 1,
                                                                           on_data: an_instance_of(Proc))
      expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'dir/file2.txt', version: 1,
                                                                           on_data: an_instance_of(Proc))
    end
  end

  context 'when the content files are not found in preservation' do
    before do
      allow(Preservation::Client.objects).to receive(:content).and_raise(Preservation::Client::NotFoundError)
    end

    it 'raises' do
      expect { stage }.to raise_error(ShelvableFilesStager::FileNotFound)
    end
  end
end
