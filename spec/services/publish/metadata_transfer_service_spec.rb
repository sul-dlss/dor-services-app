# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::MetadataTransferService do
  describe '#publish' do
    let(:druid) { 'druid:bc123df4567' }

    let(:publish_job) { class_double(PublishJob, perform_later: nil) }

    let(:member_druid) { 'druid:hx532dd9509' }
    let(:constituent_druid) { 'druid:hx532dd9509' }
    let(:uuid) { 'fe54b4a9-220f-4522-9ce6-0453c716dca6' }

    let(:closed_at) { DateTime.new(2001, 2, 3, 4, 5, 6) }

    let(:workspace_content_pathname) { Pathname.new('tmp/dor/workspace/bc/123/df/4567/bc123df4567/content') }

    before do
      allow(PublishJob).to receive(:set).with(queue: :publish_low).and_return(publish_job)
      allow(PurlFetcher::Client::Publish).to receive(:publish)
      allow(Publish::PublicCocinaService).to receive(:create).and_return(public_cocina)
      allow(Publish::TransferStager).to receive(:copy)
    end

    context 'when a collection' do
      let(:public_cocina) { instance_double(Cocina::Models::Collection, externalIdentifier: druid, dro?: false) }

      before do
        create(:repository_object_version, :collection_repository_object_version, :with_repository_object,
               external_identifier: druid, closed_at:)
        allow(MemberService).to receive(:for).and_return([member_druid])
      end

      it 'publishes the collection and its members' do
        described_class.publish(druid:)

        expect(MemberService).to have_received(:for).with(druid, publishable: true)
        expect(publish_job).to have_received(:perform_later).once.with(druid: member_druid,
                                                                       background_job_result: BackgroundJobResult)
        expect(PurlFetcher::Client::Publish).to have_received(:publish)
          .with(cocina: public_cocina, file_uploads: {}, version: 1, must_version: false, version_date: closed_at)
        expect(Publish::TransferStager).not_to have_received(:copy)
      end
    end

    context 'when a discoverable DRO' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      let(:structural) do
        { contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                  label: '00001.html',
                  filename: '00001.html',
                  size: 0,
                  version: 1,
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  hasMessageDigests: [
                    {
                      type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    }, {
                      type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                    }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: true, sdrPreserve: true, shelve: true }
                },
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                  label: 'not published',
                  filename: '00002.html',
                  size: 0,
                  version: 1,
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  hasMessageDigests: [
                    {
                      type: 'sha1', digest: 'bc19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    }, {
                      type: 'md5', digest: '6ed52da47a5ade91ae31227b978fb023'
                    }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: false, sdrPreserve: true, shelve: false }
                }
              ]
            }
          }
        ] }
      end

      before do
        repository_object_version = create(:repository_object_version, :with_repository_object,
                                           external_identifier: druid, closed_at:, structural:)
        repository_object_version.repository_object.open_version!(description: 'This is a draft repository object ' \
                                                                               'version; it should not be used.')
        allow(DigitalStacksDiffer).to receive(:call).and_return(['00001.html'], [])
        allow(ShelvableFilesStager).to receive(:stage)
        allow(SecureRandom).to receive(:uuid).and_return(uuid)
      end

      it 'publishes the item' do
        described_class.publish(druid:)

        expect(DigitalStacksDiffer).to have_received(:call).with(cocina_object: public_cocina).twice
        expect(ShelvableFilesStager).to have_received(:stage)
          .with(cocina_object: Cocina::Models::DROWithMetadata, filepaths: ['00001.html'],
                workspace_content_pathname: Pathname.new('tmp/dor/workspace/bc/123/df/4567/bc123df4567/content'))
        expect(Publish::TransferStager).to have_received(:copy)
          .with(druid:, filepath_map: { '00001.html' => uuid }, workspace_content_pathname:)
        expect(PurlFetcher::Client::Publish).to have_received(:publish)
          .with(cocina: public_cocina, file_uploads: { '00001.html' => uuid }, version: 1,
                must_version: false, version_date: closed_at)
      end
    end

    context 'when a discoverable DRO with a user version' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      let(:structural) do
        { contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                  label: '00001.html',
                  filename: '00001.html',
                  size: 0,
                  version: 1,
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  hasMessageDigests: [
                    {
                      type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    }, {
                      type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                    }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: true, sdrPreserve: true, shelve: true }
                },
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                  label: 'not published',
                  filename: '00002.html',
                  size: 0,
                  version: 1,
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  hasMessageDigests: [
                    {
                      type: 'sha1', digest: 'bc19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    }, {
                      type: 'md5', digest: '6ed52da47a5ade91ae31227b978fb023'
                    }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: false, sdrPreserve: true, shelve: false }
                }
              ]
            }
          }
        ] }
      end

      before do
        repository_object_version = create(:repository_object_version, :with_repository_object,
                                           external_identifier: druid, closed_at:, structural:)
        create(:user_version, repository_object_version:, version: 2)
        allow(DigitalStacksDiffer).to receive(:call).and_return(['00001.html'], [])
        allow(ShelvableFilesStager).to receive(:stage)
        allow(SecureRandom).to receive(:uuid).and_return(uuid)
      end

      it 'publishes the item' do
        described_class.publish(druid:)

        expect(DigitalStacksDiffer).to have_received(:call).with(cocina_object: public_cocina).twice
        expect(ShelvableFilesStager).to have_received(:stage)
          .with(cocina_object: Cocina::Models::DROWithMetadata, filepaths: ['00001.html'],
                workspace_content_pathname: Pathname.new('tmp/dor/workspace/bc/123/df/4567/bc123df4567/content'))
        expect(Publish::TransferStager).to have_received(:copy)
          .with(druid:, filepath_map: { '00001.html' => uuid }, workspace_content_pathname:)
        expect(PurlFetcher::Client::Publish).to have_received(:publish)
          .with(cocina: public_cocina, file_uploads: { '00001.html' => uuid }, version: 2, must_version: true,
                version_date: closed_at)
      end
    end

    context 'when a dark DRO' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      before do
        create(:repository_object_version, :with_repository_object, external_identifier: druid, closed_at:,
                                                                    access: { view: 'dark' })
        allow(PurlFetcher::Client::Unpublish).to receive(:unpublish)
      end

      it 'unpublishes the item' do
        described_class.publish(druid:)

        expect(PurlFetcher::Client::Unpublish).to have_received(:unpublish).with(druid:, version: 1)
      end
    end

    context 'when a dark DRO is already unpublished' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      before do
        create(:repository_object_version, :with_repository_object, external_identifier: druid, closed_at:,
                                                                    access: { view: 'dark' })
        allow(PurlFetcher::Client::Unpublish).to receive(:unpublish)
          .and_raise(PurlFetcher::Client::AlreadyDeletedResponseError)
      end

      it 'ignores the error' do
        described_class.publish(druid:)

        expect(PurlFetcher::Client::Unpublish).to have_received(:unpublish).with(druid:, version: 1)
      end
    end

    context 'when a virtual object' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      before do
        create(:repository_object_version, :with_repository_object, external_identifier: druid, closed_at:)
        allow(DigitalStacksDiffer).to receive(:call).and_return([])
        allow(VirtualObjectService).to receive(:constituents).and_return([constituent_druid])
      end

      it 'publishes the virtual object and its constituents' do
        described_class.publish(druid:)

        expect(VirtualObjectService).to have_received(:constituents)
          .with(Cocina::Models::DROWithMetadata, publishable: true)
        expect(publish_job).to have_received(:perform_later)
          .once
          .with(druid: constituent_druid, background_job_result: BackgroundJobResult)
        expect(PurlFetcher::Client::Publish).to have_received(:publish)
          .with(cocina: public_cocina, file_uploads: {}, version: 1, must_version: false, version_date: closed_at)
        expect(Publish::TransferStager).not_to have_received(:copy)
      end
    end

    context 'when a file missing from shelves' do
      let(:public_cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true) }

      let(:structural) do
        { contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                  label: '00001.html',
                  filename: '00001.html',
                  size: 0,
                  version: 1,
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  hasMessageDigests: [
                    {
                      type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    }, {
                      type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                    }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: true, sdrPreserve: true, shelve: true }
                }
              ]
            }
          }
        ] }
      end

      before do
        repository_object_version = create(:repository_object_version, :with_repository_object,
                                           external_identifier: druid, closed_at:, structural:)
        repository_object_version.repository_object
                                 .open_version!(description: 'This is a draft repository object version; it should not be used.') # rubocop:disable Layout/LineLength
        allow(DigitalStacksDiffer).to receive(:call).and_return(['00001.html'])
        allow(ShelvableFilesStager).to receive(:stage)
        allow(SecureRandom).to receive(:uuid).and_return(uuid)
      end

      it 'raises' do
        expect { described_class.publish(druid:) }.to raise_error('Files are missing from stacks: ["00001.html"]')
      end
    end
  end
end
