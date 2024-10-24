# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvableFilesStager do
  let(:cocina_object) { build(:dro, id: druid, version:) }

  let(:workspace_root) { Dir.mktmpdir }
  let(:druid) { 'druid:jq937jp0017' }
  let(:version) { 2 }
  let(:workspace_druid) { DruidTools::Druid.new(druid, workspace_root) }

  # create an empty workspace location for object content files
  let(:content_dir) { Pathname(workspace_druid.path('content', true)) }

  let(:filepaths) { ['file1.txt', 'dir/file2.txt'] }

  describe '#stage' do
    subject(:stage) { described_class.stage(cocina_object:, workspace_content_pathname: content_dir, filepaths:) }

    context 'when the content files are in the workspace area' do
      before do
        allow(Preservation::Client.objects).to receive(:content)

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
      before do
        allow(Preservation::Client.objects).to receive(:content)
      end

      # Note that for this test, the expected file size check passes because there are no matching files in the cocina.
      it 'retrieve files from preservation' do
        stage
        expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'file1.txt', version: 2,
                                                                             on_data: an_instance_of(Proc))
        expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'dir/file2.txt', version: 2,
                                                                             on_data: an_instance_of(Proc))
      end
    end

    context 'when the content files are not found in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'file1.txt', version: 2,
                                                                      on_data: an_instance_of(Proc))
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'dir/file2.txt', version: 2,
                                                                      on_data: an_instance_of(Proc)).and_raise(Preservation::Client::NotFoundError)
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'dir/file2.txt', version: 1,
                                                                      on_data: an_instance_of(Proc)).and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises' do
        expect { stage }.to raise_error(ShelvableFilesStager::FileNotFound)
      end
    end

    context 'when the content file is found on version - 1' do
      before do
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'file1.txt', version: 2,
                                                                      on_data: an_instance_of(Proc))
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'dir/file2.txt', version: 2,
                                                                      on_data: an_instance_of(Proc)).and_raise(Preservation::Client::NotFoundError)
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'dir/file2.txt', version: 1,
                                                                      on_data: an_instance_of(Proc))
      end

      it 'retrieves the files from preservation' do
        stage
        expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'file1.txt', version: 2,
                                                                             on_data: an_instance_of(Proc))
        expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'dir/file2.txt', version: 2,
                                                                             on_data: an_instance_of(Proc))
        expect(Preservation::Client.objects).to have_received(:content).with(druid:, filepath: 'dir/file2.txt', version: 1,
                                                                             on_data: an_instance_of(Proc))
      end
    end

    context 'when the content files are not found in preservation and version is 1' do
      let(:version) { 1 }

      before do
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'file1.txt', version: 1,
                                                                      on_data: an_instance_of(Proc))
        allow(Preservation::Client.objects).to receive(:content).with(druid:, filepath: 'dir/file2.txt', version: 1,
                                                                      on_data: an_instance_of(Proc)).and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises after only trying to retrieve version 1' do
        expect { stage }.to raise_error(ShelvableFilesStager::FileNotFound)
      end
    end
  end

  describe '#check_filesize' do
    subject(:check_file_size) { described_class.new(filepaths:, cocina_object:, workspace_content_pathname: content_dir).send(:check_filesize, file_pathname: content_dir.join('file1.txt'), filepath: 'file1.txt', received: received_bytes) }

    let(:cocina_object) do
      build(:dro, id: druid, version: 2).new(access: { view: 'world' }, structural: Cocina::Models::DROStructural.new(
        contains: [
          Cocina::Models::FileSet.new(
            externalIdentifier: 'bc123df4567_2',
            type: Cocina::Models::FileSetType.file,
            label: 'text file',
            version: 1,
            structural: Cocina::Models::FileSetStructural.new(
              contains: [
                Cocina::Models::File.new(
                  externalIdentifier: '1234',
                  type: Cocina::Models::ObjectType.file,
                  label: 'file1.txt',
                  filename: 'file1.txt',
                  version: 1,
                  size: 9,
                  hasMessageDigests: [
                    { type: 'md5', digest: '327d41a48b459a2807d750324bd864ce' }
                  ],
                  administrative: {
                    publish: true,
                    shelve: true
                  }
                )
              ]
            )
          )
        ]
      ))
    end

    context 'when the content length matches' do
      let(:received_bytes) { 9 }

      it 'does not raise' do
        expect { check_file_size }.not_to raise_error
      end
    end

    context 'when the content length does not match' do
      let(:received_bytes) { 10 }

      it 'raises' do
        expect { check_file_size }.to raise_error('File copied from preservation was not the expected size. Expected 9 bytes for file1.txt; received 10 bytes.')
      end
    end
  end
end
