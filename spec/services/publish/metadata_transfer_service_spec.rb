# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::MetadataTransferService do
  let(:druid) { 'bc123df4567' }
  let(:access) { {} }
  let(:workflow) { 'accessionWF' }
  let(:cocina_object) do
    build(:dro, id: "druid:#{druid}").new(
      access:,
      structural: { contains: [], isMemberOf: ['druid:xh235dd9059'] },
      administrative: {
        hasAdminPolicy: 'druid:fg890hx1234'
      }
    )
  end
  let(:cocina_collection) { build(:collection, id: 'druid:xh235dd9059') }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }
  let(:service) { described_class.new(cocina_object, workflow:) }

  describe '#publish' do
    before do
      allow(OpenURI).to receive(:open_uri).with("https://purl-test.stanford.edu/#{druid}.xml").and_return('<xml/>')
      allow(CocinaObjectStore).to receive(:find).with("druid:#{druid}").and_return(cocina_object)
      allow(CocinaObjectStore).to receive(:find).with('druid:xh235dd9059').and_return(cocina_collection) # collection object
      allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
    end

    describe 'publishing a collection with members' do
      let(:cocina_object) do
        build(:collection, id: 'druid:xh235dd9059').new(
          access: { view: 'world' }
        )
      end
      let(:fake_publish_job) { class_double(PublishJob, perform_later: nil) }
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
        allow_any_instance_of(described_class).to receive(:transfer_to_document_store)
        allow_any_instance_of(described_class).to receive(:transfer_metadata)
        allow_any_instance_of(described_class).to receive(:publish_notify_on_success)
        allow(MemberService).to receive(:for).and_return([member_druid])
        allow(CocinaObjectStore).to receive(:find).with(member_druid).and_return(member_item)
        allow(described_class).to receive(:new).with(cocina_object, workflow:).and_call_original
        allow(PublishJob).to receive(:set).with(queue: :publish_low).and_return(fake_publish_job)
      end

      it 'republishes member items' do
        service.publish
        expect(MemberService).to have_received(:for).once
        expect(fake_publish_job).to have_received(:perform_later).once.with(druid: member_druid, background_job_result: BackgroundJobResult.last, workflow:, log_success: false)
      end
    end

    context 'with no world discover access in rightsMetadata' do
      let(:purl_root) { Dir.mktmpdir }

      before do
        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')
        allow(Settings.stacks).to receive(:local_document_cache_root).and_return(purl_root)

        stub_request(:delete, "example.com/purl/purls/#{druid}")
      end

      after do
        FileUtils.remove_entry purl_root
      end

      it "removes the item's content from the Purl document cache and notifies the purl service of the deletion" do
        # create druid tree and dummy content in purl root
        druid1 = DruidTools::Druid.new cocina_object.externalIdentifier, purl_root
        druid1.mkdir
        File.write(File.join(druid1.path, 'tmpfile'), 'junk')
        service.publish
        expect(File).not_to exist(druid1.path) # it should now be gone
        expect(WebMock).to have_requested(:delete, "example.com/purl/purls/#{druid}")
      end
    end

    describe 'copies to the document cache' do
      let(:mods) do
        <<-EOXML
          <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                     version="3.3"
                     xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cosimo.stanford.edu/standards/mods/v3/mods-3-3.xsd">
            <mods:identifier type="local" displayLabel="SUL Resource ID">druid:bc123df4567</mods:identifier>
          </mods:mods>
        EOXML
      end
      let(:md_service) { instance_double(Publish::PublicDescMetadataService, to_xml: mods, ng_xml: Nokogiri::XML(mods)) }
      let(:dc_service) { instance_double(Publish::DublinCoreService, ng_xml: Nokogiri::XML('<oai_dc:dc></oai_dc:dc>')) }
      let(:public_service) { instance_double(Publish::PublicXmlService, to_xml: '<publicObject></publicObject>') }

      before do
        allow(Publish::DublinCoreService).to receive(:new).and_return(dc_service)
        allow(Publish::PublicXmlService).to receive(:new).and_return(public_service)
        allow(Publish::PublicDescMetadataService).to receive(:new).and_return(md_service)
      end

      context 'with an item' do
        before do
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/{"cocinaVersion"/, 'cocina.json')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<publicObject/, 'public')
          expect_any_instance_of(described_class).to receive(:publish_notify_on_success).with(cocina_object)
        end

        let(:access) { { view: 'citation-only', download: 'none' } }

        it 'identityMetadata, contentMetadata, rightsMetadata, generated dublin core, and public xml' do
          service.publish
          expect(Publish::PublicXmlService).to have_received(:new).with(public_cocina: Cocina::Models::DRO, thumbnail_service:)
        end
      end

      context 'with a collection object' do
        let(:cocina_object) do
          build(:collection, id: 'druid:xh235dd9059').new(
            access: { view: 'world' }
          )
        end

        before do
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/{"cocinaVersion"/, 'cocina.json')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<publicObject/, 'public')
          expect_any_instance_of(described_class).to receive(:publish_notify_on_success).with(cocina_object)
          expect_any_instance_of(described_class).to receive(:republish_members!).with(no_args)
        end

        it 'ignores missing data' do
          expect { service.publish }.not_to raise_error
        end
      end
    end
  end

  describe '#publish_notify_on_success' do
    subject(:notify) { service.send(:publish_notify_on_success, cocina_object) }

    context 'when purl-fetcher is configured' do
      before do
        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')
        allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
        allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)

        stub_request(:post, "example.com/purl/purls/#{druid}")
      end

      it 'notifies the purl service of the update' do
        notify
        expect(WebMock).to have_requested(:post, "example.com/purl/purls/#{druid}")
      end
    end

    context 'when purl-fetcher is not configured' do
      let(:purl_root) { Dir.mktmpdir }
      let(:changes_dir) { Dir.mktmpdir }
      let(:changes_file) { File.join(changes_dir, druid) }

      before do
        allow(Settings).to receive(:purl_services_url).and_return(nil)
        allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
      end

      it 'writes empty notification file' do
        expect { notify }.to raise_error 'You have not configured purl-fetcher (Settings.purl_services_url).'
      end
    end
  end

  describe '#transfer_to_document_store' do
    let(:purl_root) { Dir.mktmpdir }
    let(:workspace_root) { Dir.mktmpdir }

    before do
      allow(Settings.stacks).to receive_messages(local_document_cache_root: purl_root, local_workspace_root: workspace_root)
      allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
    end

    after do
      FileUtils.remove_entry purl_root
      FileUtils.remove_entry workspace_root
    end

    it 'copies the given metadata to the document cache in the Digital Stacks' do
      dr = DruidTools::PurlDruid.new cocina_object.externalIdentifier, purl_root
      service.send(:transfer_to_document_store, '<xml/>', 'someMd')
      file_path = dr.find(:content, 'someMd')
      expect(file_path).to match(%r{4567/someMd$})
      expect(File.read(file_path)).to eq('<xml/>')
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
