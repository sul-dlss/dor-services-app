# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicDescMetadataService do
  subject(:service) { described_class.new(obj, cocina_object) }

  let(:obj) { instantiate_fixture('druid:bc123df4567', Dor::Item) }
  let(:access) { {} }
  let(:structural) { {} }
  let(:description) do
    { title: [{ value: 'stuff' }], purl: 'https://purl.stanford.edu/bc123df4567' }
  end
  let(:cocina_object) do
    Cocina::Models.build({
                           'type' => Cocina::Models::Vocab.object,
                           'label' => 'test',
                           'externalIdentifier' => 'druid:bc123df4567',
                           'access' => access,
                           'version' => 1,
                           'structural' => structural,
                           'administrative' => {
                             'hasAdminPolicy' => 'druid:bz845pv2292'
                           },
                           'description' => description,
                           'identification' => {}
                         })
  end

  let(:solr_response) { { 'response' => { 'docs' => virtual_object_solr_docs } } }
  let(:virtual_object_solr_docs) { [] }
  let(:solr_client) { instance_double(RSolr::Client, get: solr_response) }

  before do
    allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(solr_client)
  end

  describe '#ng_xml' do
    subject(:doc) { service.ng_xml }

    context 'when it is a member of a collection' do
      let(:structural) { { isMemberOf: ['druid:xh235dd9059'] } }

      let(:collection) do
        Cocina::Models.build({
                               'type' => Cocina::Models::Vocab.collection,
                               'label' => 'test',
                               'externalIdentifier' => 'druid:xh235dd9059',
                               'access' => {},
                               'version' => 1,
                               'administrative' => {
                                 'hasAdminPolicy' => 'druid:bz845pv2292'
                               },
                               'description' => {
                                 title: [
                                   { value: 'David Rumsey Map Collection at Stanford University Libraries' }
                                 ],
                                 purl: 'https://purl-test.stanford.edu/xh235dd9059'
                               },
                               'identification' => {}
                             })
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with('druid:xh235dd9059').and_return(collection)
      end

      it 'writes the relationships into MODS' do
        # test that we have 2 expansions
        expect(doc.xpath('//mods:mods/mods:relatedItem[@type="host"]', 'mods' => 'http://www.loc.gov/mods/v3').size).to eq(1)

        # test the validity of the collection expansion
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and not(@displayLabel)]/mods:titleInfo/mods:title'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to eq('David Rumsey Map Collection at Stanford University Libraries')
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and not(@displayLabel)]/mods:location/mods:url'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to match(%r{^https?://purl.*\.stanford\.edu/xh235dd9059$})
      end
    end

    context 'with isConstituentOf relationships' do
      let(:relationships) do
        <<-EOXML
          <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
            <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
              <hydra:isGovernedBy rdf:resource="info:fedora/druid:789012"></hydra:isGovernedBy>
              <fedora-model:hasModel rdf:resource="info:fedora/hydra:commonMetadata"></fedora-model:hasModel>
              <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"></fedora:isConstituentOf>
            </rdf:Description>
          </rdf:RDF>
        EOXML
      end

      let(:virtual_object_solr_docs) { [{ 'id' => 'druid:hj097bm8879', 'sw_display_title_tesim' => ["Carey's American Atlas: Containing Twenty Maps"] }] }

      it 'writes the relationships into MODS' do
        # test that we have 2 expansions
        expect(doc.xpath('//mods:mods/mods:relatedItem[@type="host"]', 'mods' => 'http://www.loc.gov/mods/v3').size).to eq(1)

        # test the validity of the constituent expansion
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and @displayLabel="Appears in"]/mods:titleInfo/mods:title'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to start_with("Carey's American Atlas: Containing Twenty Maps")
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and @displayLabel="Appears in"]/mods:location/mods:url'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to match(%r{^https://purl.*\.stanford\.edu/hj097bm8879$})
        expect(solr_client).to have_received(:get)
          .with('select', params: {
                  q: 'has_constituents_ssim:druid\:bc123df4567',
                  fl: 'id sw_display_title_tesim'
                })
      end
    end
  end

  describe '#to_xml' do
    subject(:xml) { service.to_xml }

    let(:cocina_collection) do
      Cocina::Models.build({
                             'type' => Cocina::Models::Vocab.collection,
                             'label' => 'test',
                             'externalIdentifier' => 'druid:zb871zd0767',
                             'access' => {},
                             'version' => 1,
                             'administrative' => {
                               'hasAdminPolicy' => 'druid:bz845pv2292'
                             },
                             'description' => {
                               title: [
                                 { value: 'The complete works of Henry George' }
                               ],
                               purl: 'https://purl-test.stanford.edu/zb871zd0767'
                             },
                             'identification' => {}
                           })
    end

    let(:access) do
      {
        copyright: 'Property rights reside with the repository. Copyright &#xA9; Stanford University. All Rights Reserved.',
        useAndReproductionStatement: 'Image from the Glen McLaughlin Map Collection yada ...',
        license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
      }
    end

    let(:structural) { { isMemberOf: ['druid:zb871zd0767'] } }

    before do
      allow(CocinaObjectStore).to receive(:find).with('druid:zb871zd0767').and_return(cocina_collection)
      allow(Settings.stacks).to receive(:document_cache_host).and_return('purl.stanford.edu')
    end

    context 'when using ex2_related_mods.xml' do
      let(:description) do
        { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
          purl: 'https://purl.stanford.edu/bc123df4567',
          form: [{ value: 'still image', type: 'resource type',
                   source: { value: 'MODS resource types' } },
                 { value: 'photographs, color transparencies', type: 'form' }],
          identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055',
                         note: [{ type: 'type', value: 'local', uri: 'http://id.loc.gov/vocabulary/identifiers/local',
                                  source: { value: 'Standard Identifier Schemes', uri: 'http://id.loc.gov/vocabulary/identifiers/' } }] }],
          relatedResource: [{ access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] }, type: 'part of' }],
          access: { accessContact: [{ value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }],
                    note: [{ value: 'Property rights reside with the repository.' }] } }
      end

      it 'adds collections and generates accessConditions' do
        doc = Nokogiri::XML(xml)
        expect(doc.encoding).to eq('UTF-8')
        expect(doc.xpath('//comment()').size).to eq 0
        collections = doc.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
        collection_title = doc.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
        collection_uri   = doc.search('//xmlns:relatedItem/xmlns:location/xmlns:url')
        expect(collections.length).to eq 1
        expect(collection_title.length).to eq 1
        expect(collection_uri.length).to eq 1
        expect(collection_title.first.content).to eq 'The complete works of Henry George'
        expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
        %w[useAndReproduction copyright license].each do |term|
          expect(doc.xpath("//xmlns:accessCondition[@type=\"#{term}\"]").size).to eq 1
        end
        expect(doc.xpath('//xmlns:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
        expect(doc.xpath('//xmlns:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
        expect(doc.xpath('//xmlns:accessCondition[@type="license"]').text).to eq 'This work is licensed under a Creative Commons Attribution Non Commercial 3.0 Unported license (CC BY-NC).'
      end
    end
  end

  describe '#add_doi' do
    let(:identity_metadata) do
      <<-XML
      <identityMetadata>
        <doi>10.80343/ty606df5808</doi>
      </identityMetadata>
      XML
    end

    let(:mods) { read_fixture('mods_default_ns.xml') }
    let(:obj) do
      b = Dor::Item.new(pid: 'druid:bc123df4567')
      b.descMetadata.content = mods
      b.identityMetadata.content = identity_metadata
      b
    end

    let(:public_mods) do
      service.ng_xml
    end

    it 'adds the doi in identityMetadata' do
      expect(public_mods.xpath('//mods:identifier[@type="doi"]', mods: Publish::PublicDescMetadataService::MODS_NS).to_xml).to eq(
        '<identifier type="doi" displayLabel="DOI">https://doi.org/10.80343/ty606df5808</identifier>'
      )
    end
  end

  describe '#add_access_conditions' do
    let(:access) do
      {
        copyright: 'Property rights reside with the repository. Copyright &#xA9; Stanford University. All Rights Reserved.',
        useAndReproductionStatement: 'Image from the Glen McLaughlin Map Collection yada ...',
        license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
      }
    end

    let(:license_node) { public_mods.xpath('//mods:accessCondition[@type="license"]').first }
    let(:mods) { read_fixture('ex2_related_mods.xml') }
    let(:obj) do
      Dor::Item.new(pid: 'druid:bc123df4567').tap do |b|
        b.descMetadata.content = mods
      end
    end

    let(:public_mods) do
      service.ng_xml
    end

    it 'adds useAndReproduction accessConditions' do
      expect(public_mods.xpath('//mods:accessCondition[@type="useAndReproduction"]').size).to eq 1
      expect(public_mods.xpath('//mods:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
    end

    it 'adds copyright accessConditions' do
      expect(public_mods.xpath('//mods:accessCondition[@type="copyright"]').size).to eq 1
      expect(public_mods.xpath('//mods:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
    end

    it 'adds license accessCondtitions' do
      expect(public_mods.xpath('//mods:accessCondition[@type="license"]').size).to eq 1
      expect(license_node.text).to eq 'This work is licensed under a Creative Commons Attribution Non Commercial 3.0 Unported license (CC BY-NC).'
      expect(public_mods.root.namespaces).to include('xmlns:xlink')
      expect(license_node['xlink:href']).to eq 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
    end

    context 'when source MODS does not have xlink namespace' do
      let(:mods) do
        <<~XML
          <mods:mods xmlns:mods="http://www.loc.gov/mods/v3">
            <mods:titleInfo>
                <mods:title type="main">Slides, IA, Geodesic Domes [1 of 2]</mods:title>
            </mods:titleInfo>
          </mods:mods>
        XML
      end

      it 'adds license accessCondtitions based on creativeCommons or openDataCommons statements' do
        expect(public_mods.root.namespaces).to include('xmlns:xlink')
        expect(license_node['xlink:href']).to eq 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
      end
    end

    it 'removes any pre-existing accessConditions already in the mods' do
      expect(obj.descMetadata.ng_xml.xpath('//mods:accessCondition[text()[contains(.,"Public Services")]]').count).to eq 1
      expect(public_mods.xpath('//mods:accessCondition').size).to eq 3
      expect(public_mods.xpath('//mods:accessCondition[text()[contains(.,"Public Services")]]').count).to eq 0
    end

    context 'when mods is declared as the default value' do
      let(:mods) { read_fixture('mods_default_ns.xml') }

      it 'deals with mods declared as the default xmlns' do
        expect(obj.descMetadata.ng_xml.xpath('//mods:accessCondition[text()[contains(.,"Should not be here anymore")]]', 'mods' => 'http://www.loc.gov/mods/v3').count).to eq(1)

        expect(public_mods.xpath('//mods:accessCondition', 'mods' => 'http://www.loc.gov/mods/v3').size).to eq 3
        expect(public_mods.xpath('//mods:accessCondition[text()[contains(.,"Should not be here anymore")]]', 'mods' => 'http://www.loc.gov/mods/v3').count).to eq(0)
      end
    end
  end

  describe 'add_collection_reference' do
    let(:structural) { { isMemberOf: ['druid:zb871zd0767'] } }

    let(:collection) do
      Cocina::Models.build({
                             'type' => Cocina::Models::Vocab.collection,
                             'label' => 'test',
                             'externalIdentifier' => 'druid:zb871zd0767',
                             'access' => {},
                             'version' => 1,
                             'administrative' => {
                               'hasAdminPolicy' => 'druid:bz845pv2292'
                             },
                             'description' => {
                               title: [
                                 {
                                   structuredValue: [
                                     { value: 'The', type: 'nonsorting characters' },
                                     { value: 'complete works of Henry George', type: 'main title' }
                                   ],
                                   note: [{ value: '4', type: 'nonsorting character count' }]
                                 }
                               ],
                               purl: 'https://purl-test.stanford.edu/zb871zd0767'
                             },
                             'identification' => {}
                           })
    end

    before do
      allow(CocinaObjectStore).to receive(:find).with('druid:zb871zd0767').and_return(collection)
      allow(Settings.stacks).to receive(:document_cache_host).and_return('purl.stanford.edu')
    end

    describe 'relatedItem' do
      let(:mods) { read_fixture('ex2_related_mods.xml') }
      let(:public_mods) { service.ng_xml }

      before do
        obj.descMetadata.content = mods
      end

      context 'when the item is a member of a collection' do
        let(:description) do
          { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
            purl: 'https://purl.stanford.edu/bc123df4567',
            form: [{ value: 'still image', type: 'resource type',
                     source: { value: 'MODS resource types' } },
                   { value: 'photographs, color transparencies', type: 'form' }],
            identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055',
                           note: [{ type: 'type', value: 'local', uri: 'http://id.loc.gov/vocabulary/identifiers/local',
                                    source: { value: 'Standard Identifier Schemes', uri: 'http://id.loc.gov/vocabulary/identifiers/' } }] }],
            relatedResource: [{ access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] }, type: 'part of' }],
            access: { accessContact: [{ value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }],
                      note: [{ value: 'Property rights reside with the repository.' }] } }
        end

        it 'adds a relatedItem node for the collection' do
          collections      = public_mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//mods:relatedItem/mods:titleInfo/mods:title')
          collection_uri   = public_mods.search('//mods:relatedItem/mods:location/mods:url')
          expect(collections.length).to eq 1
          expect(collection_title.length).to eq 1
          expect(collection_uri.length).to eq 1
          expect(collection_title.first.content).to eq 'The complete works of Henry George'
          expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
        end
      end

      it 'replaces an existing relatedItem if there is a parent collection with title' do
        collections      = public_mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']')
        collection_title = public_mods.search('//mods:relatedItem/mods:titleInfo/mods:title')
        collection_uri   = public_mods.search('//mods:relatedItem/mods:location/mods:url')
        expect(collections.length).to eq 1
        expect(collection_title.length).to eq 1
        expect(collection_uri.length).to eq 1
        expect(collection_title.first.content).to eq 'The complete works of Henry George'
        expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
      end

      context 'if there is no collection relationship' do
        let(:structural) { { isMemberOf: [] } }

        let(:descriptive) do
          { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
            purl: 'https://purl.stanford.edu/zb871zd0767',
            form: [{ value: 'still image', type: 'resource type',
                     source: { value: 'MODS resource types' } }, { value: 'photographs, color transparencies', type: 'form' }],
            identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055',
                           note: [{ type: 'type', value: 'local', uri: 'http://id.loc.gov/vocabulary/identifiers/local',
                                    source: { value: 'Standard Identifier Schemes', uri: 'http://id.loc.gov/vocabulary/identifiers/' } }] }],
            relatedResource: [{ title: [{ value: 'Buckminster Fuller papers, 1920-1983' }],
                                form: [{ value: 'collection', source: { value: 'MODS resource types' } }], type: 'part of' },
                              { access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] },
                                type: 'part of' }],
            access: { accessContact: [
              { value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }
            ],
                      note: [{ value: 'Property rights reside with the repository.' }] } }
        end

        it 'does not touch an existing relatedItem if there is no collection relationship' do
          collections      = public_mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//mods:relatedItem/mods:titleInfo/mods:title')
          expect(collections.length).to eq 1
          expect(collection_title.length).to eq 1
          expect(collection_title.first.content).to eq 'Buckminster Fuller papers, 1920-1983'
        end
      end

      context 'if the referenced collection does not exist' do
        let(:structural) { { isMemberOf: [non_existent_druid] } }

        let(:non_existent_druid) { 'druid:xx000xx0000' }

        before do
          allow(CocinaObjectStore).to receive(:find).with(non_existent_druid).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
        end

        it 'does not add relatedItem and does not error out if the referenced collection does not exist' do
          collections      = public_mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//mods:relatedItem/mods:titleInfo/mods:title')
          collection_uri   = public_mods.search('//mods:relatedItem/mods:location/mods:url')
          expect(collections.length).to eq 0
          expect(collection_title.length).to eq 0
          expect(collection_uri.length).to eq 0
        end
      end
    end
  end
end
