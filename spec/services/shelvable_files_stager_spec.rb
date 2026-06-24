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
        allow(Preservation::Client.objects).to receive(:content_to_file)

        filepaths.each do |filepath|
          path = content_dir.join(filepath)
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end
      end

      it 'does not retrieve any files from preservation' do
        stage
        expect(Preservation::Client.objects).not_to have_received(:content_to_file)
      end
    end

    context 'when the content files are not in the workspace area' do
      before do
        allow(Preservation::Client.objects).to receive(:content_to_file)
      end

      it 'retrieves files from preservation' do
        stage
        expect(Preservation::Client.objects).to have_received(:content_to_file)
          .with(druid:, filepath: 'file1.txt', version: 2, destination_filepath: instance_of(String), expected_md5: nil)
        expect(Preservation::Client.objects).to have_received(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
      end

      context 'when the cocina object has MD5 digests for the files' do
        let(:cocina_object) do
          build(:dro, id: druid, version:).new(access: { view: 'world' }, structural: Cocina::Models::DROStructural.new(
            contains: [
              Cocina::Models::FileSet.new(
                externalIdentifier: 'bc123df4567_2',
                type: Cocina::Models::FileSetType.file,
                label: 'text files',
                version: 2,
                structural: Cocina::Models::FileSetStructural.new(
                  contains: [
                    Cocina::Models::File.new(
                      externalIdentifier: '1234',
                      type: Cocina::Models::ObjectType.file,
                      label: 'file1.txt',
                      filename: 'file1.txt',
                      version: 2,
                      hasMessageDigests: [{ type: 'md5', digest: 'abc123' }],
                      administrative: { publish: true, shelve: true }
                    ),
                    Cocina::Models::File.new(
                      externalIdentifier: '5678',
                      type: Cocina::Models::ObjectType.file,
                      label: 'dir/file2.txt',
                      filename: 'dir/file2.txt',
                      version: 2,
                      hasMessageDigests: [{ type: 'md5', digest: 'def456' }],
                      administrative: { publish: true, shelve: true }
                    )
                  ]
                )
              )
            ]
          ))
        end

        it 'passes the MD5 digest to the preservation client' do
          stage
          expect(Preservation::Client.objects).to have_received(:content_to_file)
            .with(druid:, filepath: 'file1.txt', version: 2,
                  destination_filepath: instance_of(String), expected_md5: 'abc123')
          expect(Preservation::Client.objects).to have_received(:content_to_file)
            .with(druid:, filepath: 'dir/file2.txt', version: 2,
                  destination_filepath: instance_of(String), expected_md5: 'def456')
        end
      end
    end

    context 'when the content files are not found in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'file1.txt', version: 2, destination_filepath: instance_of(String), expected_md5: nil)
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
          .and_raise(Preservation::Client::NotFoundError)
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 1, destination_filepath: instance_of(String),
                expected_md5: nil)
          .and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises' do
        expect { stage }.to raise_error(ShelvableFilesStager::FileNotFound)
      end
    end

    context 'when the content file is found on version - 1' do
      before do
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'file1.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
          .and_raise(Preservation::Client::NotFoundError)
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 1, destination_filepath: instance_of(String),
                expected_md5: nil)
      end

      it 'retrieves the files from preservation' do
        stage
        expect(Preservation::Client.objects).to have_received(:content_to_file)
          .with(druid:, filepath: 'file1.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
        expect(Preservation::Client.objects).to have_received(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 2, destination_filepath: instance_of(String),
                expected_md5: nil)
        expect(Preservation::Client.objects).to have_received(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 1, destination_filepath: instance_of(String),
                expected_md5: nil)
      end
    end

    context 'when the content files are not found in preservation and version is 1' do
      let(:version) { 1 }

      before do
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'file1.txt', version: 1, destination_filepath: instance_of(String),
                expected_md5: nil)
        allow(Preservation::Client.objects).to receive(:content_to_file)
          .with(druid:, filepath: 'dir/file2.txt', version: 1, destination_filepath: instance_of(String),
                expected_md5: nil)
          .and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises after only trying to retrieve version 1' do
        expect { stage }.to raise_error(ShelvableFilesStager::FileNotFound)
      end
    end
  end
end
