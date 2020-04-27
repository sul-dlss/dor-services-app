# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishMetadataService do
  let(:item) do
    instantiate_fixture('druid:ab123cd4567', Dor::Item).tap do |i|
      i.contentMetadata.content = '<contentMetadata/>'
      i.rels_ext.content = rels
    end
  end
  let(:service) { described_class.new(item) }

  let(:rels) do
    <<-EOXML
      <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
        <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
          <hydra:isGovernedBy rdf:resource="info:fedora/druid:789012"></hydra:isGovernedBy>
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
      allow(OpenURI).to receive(:open_uri).with('https://purl-test.stanford.edu/ab123cd4567.xml').and_return('<xml/>')
    end

    context 'with no world discover access in rightsMetadata' do
      let(:purl_root) { Dir.mktmpdir }

      before do
        item.rightsMetadata.content = <<-EOXML
          <rightsMetadata objectId="druid:ab123cd4567">
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

        stub_request(:delete, 'example.com/purl/purls/ab123cd4567')
      end

      after do
        FileUtils.remove_entry purl_root
      end

      it "removes the item's content from the Purl document cache and notifies the purl service of the deletion" do
        # create druid tree and dummy content in purl root
        druid1 = DruidTools::Druid.new item.pid, purl_root
        druid1.mkdir
        File.open(File.join(druid1.path, 'tmpfile'), 'w') { |f| f.write 'junk' }
        expect(service).to receive(:unbookkeep_collections)

        service.publish
        expect(File).not_to exist(druid1.path) # it should now be gone
        expect(WebMock).to have_requested(:delete, 'example.com/purl/purls/ab123cd4567')
      end
    end

    let(:release_tags) do
      { 'Searchworks' => { 'release' => true }, 'Some_special_place' => { 'release' => true } }
    end

    # the individual steps are tested below
    context 'a public item' do
      before do
        allow(ReleaseTags).to receive(:for).and_return(release_tags)
        item.rightsMetadata.content = "<rightsMetadata><access type='discover'><machine><world/></machine></access></rightsMetadata>"
      end

      it 'calls the appropriate subfunctions' do
        allow(service).to receive(:transfer_metadata)
        allow(service).to receive(:bookkeep_collections)
        allow(service).to receive(:publish_notify_on_success)

        service.publish

        expect(service).to have_received(:transfer_metadata).with(release_tags)
        expect(service).to have_received(:bookkeep_collections)
        expect(service).to have_received(:publish_notify_on_success)
      end
    end
  end

  describe '#transfer_metadata' do
    before do
      allow(OpenURI).to receive(:open_uri).with('https://purl-test.stanford.edu/ab123cd4567.xml').and_return('<xml/>')
    end

    context 'copies to the document cache' do
      let(:mods) do
        <<-EOXML
          <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                     version="3.3"
                     xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cosimo.stanford.edu/standards/mods/v3/mods-3-3.xsd">
            <mods:identifier type="local" displayLabel="SUL Resource ID">druid:ab123cd4567</mods:identifier>
          </mods:mods>
        EOXML
      end
      let(:md_service) { instance_double(PublicDescMetadataService, to_xml: mods, ng_xml: Nokogiri::XML(mods)) }
      let(:dc_service) { instance_double(DublinCoreService, ng_xml: Nokogiri::XML('<oai_dc:dc></oai_dc:dc>')) }
      let(:public_service) { instance_double(PublicXmlService, to_xml: '<publicObject></publicObject>') }

      before do
        allow(DublinCoreService).to receive(:new).and_return(dc_service)
        allow(PublicXmlService).to receive(:new).and_return(public_service)
        allow(PublicDescMetadataService).to receive(:new).and_return(md_service)
      end

      context 'with an item' do
        before do
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<identityMetadata/, 'identityMetadata')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<contentMetadata/, 'contentMetadata')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<rightsMetadata/, 'rightsMetadata')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<oai_dc:dc/, 'dc')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<publicObject/, 'public')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<mods:mods/, 'mods')
        end

        let(:release_tags) do
          { 'Searchworks' => { 'release' => true }, 'Some_special_place' => { 'release' => true } }
        end

        it 'identityMetadta, contentMetadata, rightsMetadata, generated dublin core, and public xml' do
          item.rightsMetadata.content = "<rightsMetadata><access type='discover'><machine><world/></machine></access></rightsMetadata>"
          service.send(:transfer_metadata, release_tags)
          expect(DublinCoreService).to have_received(:new).with(item)
          expect(PublicXmlService).to have_received(:new).with(item, released_for: release_tags)
          expect(PublicDescMetadataService).to have_received(:new).with(item)
        end

        it 'even when rightsMetadata uses xml namespaces' do
          item.rightsMetadata.content = %q(<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1">
            <access type='discover'><machine><world/></machine></access></rightsMetadata>)
          service.send(:transfer_metadata, release_tags)
        end
      end

      context 'with a collection object' do
        let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Collection) }

        before do
          item.descMetadata.content = mods
          item.rightsMetadata.content = "<rightsMetadata><access type='discover'><machine><world/></machine></access></rightsMetadata>"
          item.rels_ext.content = rels
        end

        before do
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<identityMetadata/, 'identityMetadata')
          expect_any_instance_of(described_class).not_to receive(:transfer_to_document_store).with(/<contentMetadata/, 'contentMetadata')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<rightsMetadata/, 'rightsMetadata')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<oai_dc:dc/, 'dc')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<publicObject/, 'public')
          expect_any_instance_of(described_class).to receive(:transfer_to_document_store).with(/<mods:mods/, 'mods')
        end

        it 'ignores missing data' do
          service.send(:transfer_metadata, {})
        end
      end
    end
  end

  describe '#bookkeep_collections' do
    it 'adds a link from the item to the collection' do
    end

    it 'adds a link from the collection to the item' do
    end

    it 'cleans up links that are not expressed in the item' do
    end
  end

  describe '#unbookkeep_collections' do
    it 'cleans up links from collections to this item' do
    end

    it 'cleans up links from items to this collection' do
    end
  end

  describe '#publish_notify_on_success' do
    subject(:notify) { service.send(:publish_notify_on_success) }

    context 'when purl-fetcher is configured' do
      before do
        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')

        stub_request(:post, 'example.com/purl/purls/ab123cd4567')
      end

      it 'notifies the purl service of the update' do
        notify
        expect(WebMock).to have_requested(:post, 'example.com/purl/purls/ab123cd4567')
      end
    end

    context 'when purl-fetcher is not configured' do
      let(:purl_root) { Dir.mktmpdir }
      let(:changes_dir) { Dir.mktmpdir }
      let(:changes_file) { File.join(changes_dir, item.pid.gsub('druid:', '')) }

      before do
        allow(Settings).to receive(:purl_services_url).and_return(nil)
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
      expect(IO.read(file_path)).to eq('<xml/>')
    end
  end
end
