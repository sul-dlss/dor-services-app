# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::MetadataTransferService do
  let(:druid) { 'bc123df4567' }
  let(:access) { {} }
  let(:workflow) { 'accessionWF' }
  let(:cocina_object) do
    build(:dro, id: "druid:#{druid}").new(
      access:,
      structural: { contains: structural_contains, isMemberOf: ['druid:xh235dd9059'] },
      administrative: {
        hasAdminPolicy: 'druid:fg890hx1234'
      }
    )
  end
  let(:structural_contains) { [] }
  let(:cocina_collection) { build(:collection, id: 'druid:xh235dd9059') }
  let(:service) { described_class.new(cocina_object, workflow:) }
  let(:publish_job) { class_double(PublishJob, perform_later: nil) }

  describe '#publish' do
    before do
      allow(CocinaObjectStore).to receive(:find).with("druid:#{druid}").and_return(cocina_object)
      allow(CocinaObjectStore).to receive(:find).with('druid:xh235dd9059').and_return(cocina_collection) # collection object
    end

    describe 'publishing a collection with members' do
      let(:cocina_object) do
        build(:collection, id: 'druid:xh235dd9059').new(
          access: { view: 'world' }
        )
      end
      let(:member_druid) { 'druid:hx532dd9509' }
      let(:member_item) do
        build(:dro, id: member_druid).new(
          access: { view: 'world' },
          structural: { contains: [], isMemberOf: ['druid:xh235dd9059'] },
          administrative: {
            hasAdminPolicy: 'druid:fg890hx1234'
          }
        )
      end

      before do
        allow(MemberService).to receive(:for).and_return([member_druid])
        allow(CocinaObjectStore).to receive(:find).with(member_druid).and_return(member_item)
        allow(described_class).to receive(:new).with(cocina_object, workflow:).and_call_original
        allow(PublishJob).to receive(:set).with(queue: :publish_low).and_return(publish_job)
        allow(service).to receive(:publish_shelve)
        allow(service).to receive(:republish_virtual_object_constituents!)
        allow(service).to receive(:release_tags_on_success)
      end

      it 'republishes member items' do
        service.publish
        expect(MemberService).to have_received(:for).once
        expect(publish_job).to have_received(:perform_later).once.with(druid: member_druid, background_job_result: BackgroundJobResult.last, workflow:, log_success: false)
      end
    end

    context 'when not discoverable' do
      before do
        allow(PurlFetcher::Client::Unpublish).to receive(:unpublish)
      end

      it 'unpublishes' do
        service.publish
        expect(PurlFetcher::Client::Unpublish).to have_received(:unpublish).with(druid: cocina_object.externalIdentifier)
      end

      context 'when already deleted' do
        before do
          allow(PurlFetcher::Client::Unpublish).to receive(:unpublish).and_raise(PurlFetcher::Client::AlreadyDeletedResponseError)
        end

        it 'ignores the error' do
          expect { service.publish }.not_to raise_error
        end
      end
    end

    describe 'copies to the document cache' do
      context 'with an item' do
        before do
          allow(service).to receive(:publish_shelve)
          allow(service).to receive(:release_tags_on_success)
          allow(service).to receive(:republish_virtual_object_constituents!)
        end

        let(:access) { { view: 'citation-only', download: 'none' } }

        it 'publishes, shelves, and releases tags' do
          service.publish
          expect(service).to have_received(:publish_shelve)
          expect(service).to have_received(:release_tags_on_success)
          expect(service).to have_received(:republish_virtual_object_constituents!)
        end
      end

      context 'with a collection object' do
        let(:cocina_object) do
          build(:collection, id: 'druid:xh235dd9059').new(
            access: { view: 'world' }
          )
        end

        before do
          allow(service).to receive(:publish_shelve)
          allow(service).to receive(:release_tags_on_success)
          allow(service).to receive(:republish_virtual_object_constituents!)
          allow(service).to receive(:republish_collection_members!)
        end

        it 'publishes, shelves, and releases tags' do
          service.publish
          expect(service).to have_received(:publish_shelve)
          expect(service).to have_received(:release_tags_on_success)
          expect(service).to have_received(:republish_virtual_object_constituents!)
          expect(service).to have_received(:republish_collection_members!).with(no_args)
        end
      end
    end
  end

  describe '#release_tags_on_success' do
    subject(:notify) { service.send(:release_tags_on_success) }

    before do
      create(:release_tag, druid: cocina_object.externalIdentifier, release: true)
      allow(PurlFetcher::Client::ReleaseTags).to receive(:release)
    end

    it 'notifies the purl service of the release tags' do
      notify
      expect(PurlFetcher::Client::ReleaseTags).to have_received(:release).with(druid: cocina_object.externalIdentifier, index: ['Searchworks'], delete: [])
    end
  end

  describe '#publish_shelve' do
    subject(:publish_shelve) { service.send(:publish_shelve) }

    let(:access) { { view: 'world', download: 'none' } }

    let(:structural_contains) do
      [
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/jt667tw2770-0001',
          label: '',
          version: 6,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_00_0001.tif',
                label: 'jt667tw2770_00_0001.tif',
                filename: 'jt667tw2770_00_0001.tif',
                size: 193_090_740,
                version: 6,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  { type: 'sha1', digest: 'd71f1b739d4b3ff2bf199c8e3452a16c7a6609f0' },
                  { type: 'md5', digest: 'a695ccc6ed7a9c905ba917d7c284854e' }
                ],
                access: { view: 'world', download: 'none' },
                administrative: { publish: true, sdrPreserve: true, shelve: true },
                presentation: { height: 6610, width: 9736 }
              }, {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_05_0001.jp2',
                label: 'jt667tw2770_05_0001.jp2',
                filename: 'images/jt667tw2770_05_0001.jp2',
                size: 12_141_770,
                version: 6,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [
                  { type: 'sha1', digest: 'b6632c33619e3dd6268eb1504580285670f4c3b8' },
                  { type: 'md5', digest: '9f74085aa752de7404d31cb6bcc38a56' }
                ],
                access: { view: 'world', download: 'none' },
                administrative: { publish: true, sdrPreserve: true, shelve: true },
                presentation: { height: 6610, width: 9736 }
              }
            ]
          }
        }
      ]
    end

    let(:transfer_stage_root) { Dir.mktmpdir }
    let(:workspace_root) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry transfer_stage_root
      FileUtils.remove_entry workspace_root
    end

    before do
      allow(Settings.stacks).to receive_messages(transfer_stage_root:, local_workspace_root: workspace_root)
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(PurlFetcher::Client::Publish).to receive(:publish)
      allow(DigitalStacksDiffer).to receive(:call).and_return(['images/jt667tw2770_05_0001.jp2'])
      allow(ShelvableFilesStager).to receive(:stage)
      allow(SecureRandom).to receive(:uuid).and_return('fe54b4a9-220f-4522-9ce6-0453c716dca6')
      src_filepath = File.join(workspace_root, 'bc/123/df/4567/bc123df4567/content/images/jt667tw2770_05_0001.jp2')
      FileUtils.mkdir_p(File.dirname(src_filepath))
      File.write(src_filepath, 'jp2 content')
    end

    it 'shelves and publishes' do
      publish_shelve
      expect(ShelvableFilesStager).to have_received(:stage).with(druid: "druid:#{druid}", version: 1, filepaths: ['images/jt667tw2770_05_0001.jp2'], workspace_content_pathname: Pathname(File.join(workspace_root, 'bc/123/df/4567/bc123df4567/content')))
      expect(PurlFetcher::Client::Publish).to have_received(:publish).with(cocina: Cocina::Models::DRO, file_uploads: { 'images/jt667tw2770_05_0001.jp2' => 'fe54b4a9-220f-4522-9ce6-0453c716dca6' })
    end

    context 'when a collection' do
      let(:cocina_object) do
        build(:collection, id: "druid:#{druid}").new(
          access: { view: 'world' }
        )
      end

      it 'shelves and publishes to purl fetcher service' do
        publish_shelve
        expect(DigitalStacksDiffer).not_to have_received(:call)
        expect(ShelvableFilesStager).not_to have_received(:stage)
      end
    end
  end

  describe '#republish_virtual_object_constituents' do
    subject(:republish) { service.send(:republish_virtual_object_constituents!) }

    let(:constituent_druid) { 'druid:bc123df4567' }

    before do
      allow(VirtualObjectService).to receive(:constituents).and_return([constituent_druid])
      allow(PublishJob).to receive(:set).with(queue: :publish_low).and_return(publish_job)
    end

    it 'republishes the virtual object constituents' do
      republish
      expect(VirtualObjectService).to have_received(:constituents).with(cocina_object, exclude_opened: true, only_published: true)
      expect(publish_job).to have_received(:perform_later).once.with(druid: constituent_druid, background_job_result: BackgroundJobResult.last, workflow:, log_success: false)
    end
  end

  describe '.publish' do
    let(:service) { instance_double(described_class, publish: nil) }

    before do
      allow(described_class).to receive(:new).and_return(service)
    end

    it 'calls publish on a new instance with the default workflow' do
      described_class.publish(cocina_object)
      expect(described_class).to have_received(:new).with(cocina_object, workflow: 'accessionWF')
      expect(service).to have_received(:publish)
    end

    it 'calls publish on a new instance with a specific workflow' do
      described_class.publish(cocina_object, workflow: 'releaseWF')
      expect(described_class).to have_received(:new).with(cocina_object, workflow: 'releaseWF')
      expect(service).to have_received(:publish)
    end
  end
end
