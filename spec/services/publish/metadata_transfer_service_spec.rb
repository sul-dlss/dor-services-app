# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::MetadataTransferService do
  let(:pid) { 'bc123df4567' }
  let(:item) do
    Dor::Item.new(pid: "druid:#{pid}").tap do |i|
      i.contentMetadata.content = '<contentMetadata/>'
      i.identityMetadata.content = <<~XML
        <identityMetadata>
          <release release="true" to="Searchworks" what="self" when="2015-07-27T21:44:26Z" who="lauraw15">true</release>
          <release release="true" to="Some_special_place" what="self" when="2015-08-31T23:59:59" who="atz">true</release>
        </identityMetadata>
      XML
      i.rels_ext.content = rels
      i.objectLabel = 'google download barcode 36105049267078'
      i.source_id = 'STANFORD:342837261527'
      i.barcode = '36105049267078'
      i.catkey = '129483625'
      i.admin_policy_object_id = 'druid:fg890hx1234'
      i.descMetadata.mods_title = 'Fixture title'
    end
  end
  let(:description) do
    {
      title: [{ value: 'Constituent label &amp; A Special character' }],
      purl: "https://purl.stanford.edu/#{pid}"
    }
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: "druid:#{pid}",
                            type: Cocina::Models::Vocab.object,
                            label: 'google download barcode 36105049267078',
                            version: 1,
                            description: description,
                            identification: {},
                            access: {},
                            structural: { contains: [], isMemberOf: ['druid:xh235dd9059'] },
                            administrative: { hasAdminPolicy: 'druid:fg890hx1234',
                                              releaseTags: [
                                                {
                                                  who: 'dhartwig',
                                                  what: 'collection',
                                                  date: '2019-01-18T17:03:35.000+00:00',
                                                  to: 'Searchworks',
                                                  release: true
                                                },
                                                {
                                                  who: 'dhartwig',
                                                  what: 'collection',
                                                  date: '2020-01-18T17:03:35.000+00:00',
                                                  to: 'Some_special_place',
                                                  release: true
                                                }
                                              ] })
  end
  let(:cocina_collection) do
    Cocina::Models::Collection.new(externalIdentifier: 'druid:xh235dd9059',
                                   type: Cocina::Models::Vocab.collection,
                                   label: 'some collection object',
                                   version: 1,
                                   description: description,
                                   identification: {},
                                   access: {},
                                   administrative: { hasAdminPolicy: 'druid:fg890hx1234' })
  end
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }

  let(:service) { described_class.new(item) }

  let(:rels) do
    <<-EOXML
      <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
        <rdf:Description rdf:about="info:fedora/druid:bc123df4567">
          <hydra:isGovernedBy rdf:resource="info:fedora/druid:fg890hx1234"></hydra:isGovernedBy>
          <fedora-model:hasModel rdf:resource="info:fedora/hydra:commonMetadata"></fedora-model:hasModel>
          <fedora:isMemberOf rdf:resource="info:fedora/druid:xh235dd9059"></fedora:isMemberOf>
          <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"></fedora:isMemberOfCollection>
          <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"></fedora:isConstituentOf>
        </rdf:Description>
      </rdf:RDF>
    EOXML
  end

  describe '#publish' do
    before do
      allow(OpenURI).to receive(:open_uri).with("https://purl-test.stanford.edu/#{pid}.xml").and_return('<xml/>')
      allow(CocinaObjectStore).to receive(:find).with("druid:#{pid}").and_return(cocina_object)
      allow(CocinaObjectStore).to receive(:find).with('druid:xh235dd9059').and_return(cocina_collection) # collection object
      allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
    end

    context 'with no world discover access in rightsMetadata' do
      let(:purl_root) { Dir.mktmpdir }

      before do
        item.rightsMetadata.content = <<-EOXML
          <rightsMetadata objectId="druid:bc123df4567">
            <copyright>
              <human>(c) Copyright 2010 by Sebastian Jeremias Osterfeld</human>
            </copyright>
            </access>
            <access type="read">
              <machine>
                <group>stanford:stanford</group>
              </machine>
            </access>
            <use>
              <machine type="creativeCommons">by-sa</machine>
              <human type="creativeCommons">CC Attribution Share Alike license</human>
            </use>
          </rightsMetadata>
        EOXML

        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')
        allow(Settings.stacks).to receive(:local_document_cache_root).and_return(purl_root)

        stub_request(:delete, "example.com/purl/purls/#{pid}")
      end

      after do
        FileUtils.remove_entry purl_root
      end

      it "removes the item's content from the Purl document cache and notifies the purl service of the deletion" do
        # create druid tree and dummy content in purl root
        druid1 = DruidTools::Druid.new item.pid, purl_root
        druid1.mkdir
        File.write(File.join(druid1.path, 'tmpfile'), 'junk')
        service.publish
        expect(File).not_to exist(druid1.path) # it should now be gone
        expect(WebMock).to have_requested(:delete, "example.com/purl/purls/#{pid}")
      end
    end

    context 'copies to the document cache' do
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
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<mods:mods/, 'mods')
          expect_any_instance_of(described_class).to receive(:publish_notify_on_success).with(no_args)
        end

        let(:release_tags) do
          { 'Searchworks' => { 'release' => true }, 'Some_special_place' => { 'release' => true } }
        end

        it 'identityMetadta, contentMetadata, rightsMetadata, generated dublin core, and public xml' do
          item.rightsMetadata.content = "<rightsMetadata><access type='discover'><machine><world/></machine></access></rightsMetadata>"
          service.publish
          expect(Publish::PublicXmlService).to have_received(:new).with(item, public_cocina: Cocina::Models::DRO, released_for: release_tags, thumbnail_service: thumbnail_service)
          expect(Publish::PublicDescMetadataService).to have_received(:new).with(Cocina::Models::DRO)
        end
      end

      context 'with a collection object' do
        let(:item) do
          Dor::Collection.new(pid: 'druid:xh235dd9059',
                              label: 'Simple collection',
                              admin_policy_object_id: 'druid:fg890hx1234').tap do |coll|
                                coll.descMetadata.mods_title = 'Grand collection'
                              end
        end

        before do
          item.rightsMetadata.content = "<rightsMetadata><access type='discover'><machine><world/></machine></access></rightsMetadata>"
          item.rels_ext.content = rels
        end

        before do
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/{"cocinaVersion"/, 'cocina.json')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<publicObject/, 'public')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<mods:mods/, 'mods')
          expect_any_instance_of(described_class).to receive(:publish_notify_on_success).with(no_args)
        end

        it 'ignores missing data' do
          service.publish
        end
      end
    end
  end

  describe '#publish_notify_on_success' do
    subject(:notify) { service.send(:publish_notify_on_success) }

    context 'when purl-fetcher is configured' do
      before do
        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')
        allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
        allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)

        stub_request(:post, "example.com/purl/purls/#{pid}")
      end

      it 'notifies the purl service of the update' do
        notify
        expect(WebMock).to have_requested(:post, "example.com/purl/purls/#{pid}")
      end
    end

    context 'when purl-fetcher is not configured' do
      let(:purl_root) { Dir.mktmpdir }
      let(:changes_dir) { Dir.mktmpdir }
      let(:changes_file) { File.join(changes_dir, pid) }

      before do
        allow(Settings).to receive(:purl_services_url).and_return(nil)
        allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
        allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
      end

      it 'writes empty notification file' do
        expect { notify }.to raise_error 'You have not configured perl-fetcher (Settings.purl_services_url).'
      end
    end
  end

  describe '#transfer_to_document_store' do
    let(:purl_root) { Dir.mktmpdir }
    let(:workspace_root) { Dir.mktmpdir }

    before do
      allow(Settings.stacks).to receive(:local_document_cache_root).and_return(purl_root)
      allow(Settings.stacks).to receive(:local_workspace_root).and_return(workspace_root)
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
    end

    after do
      FileUtils.remove_entry purl_root
      FileUtils.remove_entry workspace_root
    end

    it 'copies the given metadata to the document cache in the Digital Stacks' do
      dr = DruidTools::PurlDruid.new item.pid, purl_root
      service.send(:transfer_to_document_store, '<xml/>', 'someMd')
      file_path = dr.find(:content, 'someMd')
      expect(file_path).to match(%r{4567/someMd$})
      expect(File.read(file_path)).to eq('<xml/>')
    end
  end
end
