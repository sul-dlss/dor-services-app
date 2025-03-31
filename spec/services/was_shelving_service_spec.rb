# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WasShelvingService do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:,
                                         type: Cocina::Models::ObjectType.webarchive_binary)
  end
  let(:structural) do
    Cocina::Models::DROStructural.new(
      { contains: [
          { externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
            type: Cocina::Models::FileSetType.file,
            version: 1,
            label: '',
            structural: {
              contains: [
                { externalIdentifier: 'https://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                  type: Cocina::Models::ObjectType.file,
                  label: 'ARCHIVEIT-123-1.warc.gz',
                  filename: 'ARCHIVEIT-123-1.warc.gz',
                  size: 78_880,
                  version: 1,
                  hasMessageDigests: [{ type: 'sha1',
                                        digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                      { type: 'md5',
                                        digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: false, sdrPreserve: true, shelve: true },
                  hasMimeType: 'application/warc' }
              ]
            } },
          { externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-000000000',
            type: Cocina::Models::FileSetType.file,
            version: 1,
            label: '',
            structural: { contains: [{ externalIdentifier: 'https://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-00000000000',
                                       type: Cocina::Models::ObjectType.file,
                                       label: 'ARCHIVEIT-234-2.warc.gz',
                                       filename: 'ARCHIVEIT-234-2.warc.gz',
                                       size: 78_880,
                                       version: 1,
                                       hasMessageDigests: [{ type: 'sha1',
                                                             digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                           { type: 'md5',
                                                             digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                       access: { view: 'world', download: 'world' },
                                       administrative: { publish: false, sdrPreserve: true, shelve: false },
                                       hasMimeType: 'application/warc' }] } }
        ],
        isMemberOf: collections }
    )
  end
  let(:collection) { 'druid:bb077hj4590' }
  let(:collections) { [collection] }
  let(:workspace) { Pathname(File.dirname(__FILE__)).join('../fixtures/workspace') }
  let(:was_stacks_location) { "#{@tmp_stacksdir}/web-archiving-stacks/data/collections" }
  let(:tmp_was_stacks) { @tmp_stacksdir.join('web-archiving-stacks', 'data', 'collections', 'bb077hj4590') }
  let(:was_stacks_destination) { tmp_was_stacks.join('bc', '123', 'df', '4567', filename) }
  let(:filename) { 'ARCHIVEIT-123-1.warc.gz' }

  before(:all) do
    @tmp_stacksdir = Pathname(Dir.mktmpdir)
  end

  after(:all) do
    @tmp_stacksdir.rmtree if Dir.exist?(@tmp_stacksdir)
  end

  before do
    allow(Settings.stacks).to receive(:local_workspace_root).and_return(workspace).to_s
    allow(Settings.stacks).to receive(:web_archiving_stacks).and_return(was_stacks_location)
    allow(Rails.logger).to receive(:debug)
  end

  context 'when shelving web archiving crawls' do
    let(:filename2) { 'ARCHIVEIT-234-2.warc.gz' }
    let(:was_stacks_destination2) { tmp_was_stacks.join('bc', '123', 'df', '4567', filename2) }
    let(:workspace_filename) { workspace.join('bc', '123', 'df', '4567', 'bc123df4567', 'content', filename) }

    it 'copies the files to stacks' do
      described_class.shelve(cocina_object)
      expect(was_stacks_destination).to exist
      expect(was_stacks_destination2).not_to exist
      expect(Rails.logger).to have_received(:debug)
        .with("[Was Shelve] Copying #{workspace_filename} to #{was_stacks_destination}")
    end
  end

  context 'when the web-archiving-stacks location does not exist yet' do
    let(:filename) { 'ARCHIVEIT-123-1.warc.gz' }
    let(:was_stacks_dir) { tmp_was_stacks.join('bc', '123', 'df', '4567') }

    before do
      was_stacks_dir.rmtree if was_stacks_dir.exist?
    end

    it 'creates the directory' do
      expect(was_stacks_dir).not_to exist
      described_class.shelve(cocina_object)
      expect(was_stacks_dir).to exist
    end
  end

  context 'when a web archive without collection' do
    let(:collections) { [] }

    it 'raises' do
      expect { described_class.shelve(cocina_object) }.to raise_error(WasShelvingService::WasShelvingError)
    end
  end
end
