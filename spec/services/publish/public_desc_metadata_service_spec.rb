# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicDescMetadataService do
  subject(:service) { described_class.new(obj) }

  let(:pid) { 'druid:bc123df4567' }
  let(:obj) { instantiate_fixture(pid, Dor::Item) }

  before { allow(obj).to receive(:pid).and_return(pid) }

  describe '#ng_xml' do
    subject(:doc) { service.ng_xml }

    context 'with isMemberOfCollection and isConstituentOf relationships' do
      let(:relationships) do
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

      before do
        ActiveFedora::RelsExtDatastream.from_xml(relationships, obj.rels_ext)

        # load up collection and constituent parent items from fixture data
        expect(Dor).to receive(:find).with('druid:xh235dd9059').and_return(instantiate_fixture('druid:xh235dd9059', Dor::Item))
        expect(Dor).to receive(:find).with('druid:hj097bm8879').and_return(instantiate_fixture('druid:hj097bm8879', Dor::Item))
      end

      it 'writes the relationships into MODS' do
        # test that we have 2 expansions
        expect(doc.xpath('//mods:mods/mods:relatedItem[@type="host"]', 'mods' => 'http://www.loc.gov/mods/v3').size).to eq(2)

        # test the validity of the collection expansion
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and not(@displayLabel)]/mods:titleInfo/mods:title'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to eq('David Rumsey Map Collection at Stanford University Libraries')
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and not(@displayLabel)]/mods:location/mods:url'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to match(%r{^https?://purl.*\.stanford\.edu/xh235dd9059$})

        # test the validity of the constituent expansion
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and @displayLabel="Appears in"]/mods:titleInfo/mods:title'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to start_with("Carey's American Atlas: Containing Twenty Maps")
        xpath_expr = '//mods:mods/mods:relatedItem[@type="host" and @displayLabel="Appears in"]/mods:location/mods:url'
        expect(doc.xpath(xpath_expr, 'mods' => 'http://www.loc.gov/mods/v3').first.text.strip).to match(%r{^http://purl.*\.stanford\.edu/hj097bm8879$})
      end
    end
  end

  describe '#to_xml' do
    subject(:xml) { service.to_xml }

    let(:rights_xml) do
      <<-XML
      <rightsMetadata>
        <copyright>
          <human type="copyright">
            Property rights reside with the repository. Copyright &#xA9; Stanford University. All Rights Reserved.
          </human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
        <use>
          <human type="useAndReproduction">
            Image from the Glen McLaughlin Map Collection yada ...
          </human>
          <machine type="creativeCommons">by-nc</machine>
          <human type="creativeCommons">
            Attribution Non-Commercial 3.0 Unported
          </human>
        </use>
      </rightsMetadata>
      XML
    end

    let(:collection) { instantiate_fixture('druid:bc123df4567', Dor::Item) }

    before do
      allow(obj).to receive(:relationships).with(:is_member_of).and_return(['info:fedora/druid:zb871zd0767'])
      allow(obj).to receive(:relationships).with(:is_member_of_collection).and_return(['info:fedora/druid:zb871zd0767'])
      allow(obj).to receive(:relationships).with(:is_constituent_of).and_return([])
      allow(Settings.stacks).to receive(:document_cache_host).and_return('purl.stanford.edu')

      obj.rightsMetadata.content = rights_xml

      c_mods = Nokogiri::XML(read_fixture('ex1_mods.xml'))
      collection.descMetadata.content = c_mods.to_s

      allow(Dor).to receive(:find) do |pid|
        pid == 'druid:ab123cd4567' ? obj : collection
      end
    end

    context 'when using ex2_related_mods.xml' do
      before do
        mods_xml = read_fixture('ex2_related_mods.xml')
        mods = Nokogiri::XML(mods_xml)
        mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']').each do |node|
          node.parent.remove
        end
        obj.descMetadata.content = mods.to_s
      end

      it 'adds collections and generates accessConditions' do
        doc = Nokogiri::XML(xml)
        expect(doc.encoding).to eq('UTF-8')
        expect(doc.xpath('//comment()').size).to eq 0
        collections = doc.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']')
        collection_title = doc.search('//mods:relatedItem/mods:titleInfo/mods:title')
        collection_uri   = doc.search('//mods:relatedItem/mods:location/mods:url')
        expect(collections.length).to eq 1
        expect(collection_title.length).to eq 1
        expect(collection_uri.length).to eq 1
        expect(collection_title.first.content).to eq 'The complete works of Henry George'
        expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
        %w[useAndReproduction copyright license].each do |term|
          expect(doc.xpath('//mods:accessCondition[@type="' + term + '"]').size).to eq 1
        end
        expect(doc.xpath('//mods:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
        expect(doc.xpath('//mods:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
        expect(doc.xpath('//mods:accessCondition[@type="license"]').text).to eq 'CC by-nc: Attribution-NonCommercial 3.0 Unported License'
      end
    end

    context 'when using mods_default_ns.xml' do
      before do
        mods_xml = read_fixture('mods_default_ns.xml')
        mods = Nokogiri::XML(mods_xml)
        mods.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']', 'mods' => 'http://www.loc.gov/mods/v3').each do |node|
          node.parent.remove
        end
        obj.descMetadata.content = mods.to_s
      end

      it 'handles mods as the default namespace' do
        doc = Nokogiri::XML(xml)
        collections = doc.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
        collection_title = doc.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
        collection_uri   = doc.search('//xmlns:relatedItem/xmlns:location/xmlns:url')
        expect(collections.length).to eq 1
        expect(collection_title.length).to eq 1
        expect(collection_uri.length).to eq 1
        expect(collection_title.first.content).to eq 'The complete works of Henry George'
        expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
        %w[useAndReproduction copyright license].each do |term|
          expect(doc.xpath('//xmlns:accessCondition[@type="' + term + '"]').size).to eq 1
        end
        expect(doc.xpath('//xmlns:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
        expect(doc.xpath('//xmlns:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
        expect(doc.xpath('//xmlns:accessCondition[@type="license"]').text).to eq 'CC by-nc: Attribution-NonCommercial 3.0 Unported License'
      end
    end
  end

  describe '#add_access_conditions' do
    let(:rights_xml) do
      <<-XML
      <rightsMetadata>
        <copyright>
          <human type="copyright">
            Property rights reside with the repository. Copyright &#xA9; Stanford University. All Rights Reserved.
          </human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
        <use>
          <human type="useAndReproduction">
            Image from the Glen McLaughlin Map Collection yada ...
          </human>
          <machine type="creativeCommons">by-nc</machine>
          <human type="creativeCommons">
            Attribution Non-Commercial 3.0 Unported
          </human>
        </use>
      </rightsMetadata>
      XML
    end

    let(:license_node) { public_mods.xpath('//mods:accessCondition[@type="license"]').first }
    let(:mods) { read_fixture('ex2_related_mods.xml') }
    let(:obj) do
      b = Dor::Item.new
      b.descMetadata.content = mods
      b.rightsMetadata.content = rights_xml
      b
    end

    let(:public_mods) do
      service.ng_xml
    end

    it 'adds useAndReproduction accessConditions based on rightsMetadata' do
      expect(public_mods.xpath('//mods:accessCondition[@type="useAndReproduction"]').size).to eq 1
      expect(public_mods.xpath('//mods:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
    end

    it 'adds copyright accessConditions based on rightsMetadata' do
      expect(public_mods.xpath('//mods:accessCondition[@type="copyright"]').size).to eq 1
      expect(public_mods.xpath('//mods:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
    end

    it 'adds license accessCondtitions based on creativeCommons or openDataCommons statements' do
      expect(public_mods.xpath('//mods:accessCondition[@type="license"]').size).to eq 1
      expect(license_node.text).to match(/by-nc: Attribution-NonCommercial 3.0 Unported/)
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

    context 'when a license node is present in rightsMetadata' do
      before do
        obj.rightsMetadata.content = <<~XML
          <rightsMetadata>
            <use>
              <license>https://creativecommons.org/licenses/by-nd/4.0/legalcode</license>
            </use>
          </rightsMetadata>
        XML
      end

      it 'adds license accessConditions' do
        expect(license_node.text).to eq 'CC BY-ND: Attribution-No Derivatives International'
        expect(license_node['xlink:href']).to eq 'https://creativecommons.org/licenses/by-nd/4.0/legalcode'
      end
    end

    context 'when a license attribute (with a legacy URI) is present in rightsMetadata' do
      before do
        obj.rightsMetadata.content = <<~XML
          <rightsMetadata>
            <use>
              <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
              <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-nc-nd/3.0/">by-nc-nd</machine>
              <human type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</human>
            </use>
          </rightsMetadata>
        XML
        allow(Honeybadger).to receive(:notify)
      end

      it 'adds license accessConditions' do
        expect(license_node.text).to eq 'CC by-nc-nd: Attribution-NonCommercial-No Derivative Works 3.0 Unported License'
        expect(license_node['xlink:href']).to eq 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode'
        expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] https://creativecommons.org/licenses/by-nc-nd/3.0/ is not a supported license')
      end
    end

    context 'when the machine node is odc-by' do
      before do
        obj.rightsMetadata.content = <<~XML
          <rightsMetadata>
            <use>
              <machine type="openDataCommons">odc-by</machine>
            </use>
          </rightsMetadata>
        XML
      end

      it 'adds license accessConditions' do
        expect(license_node.text).to eq 'ODC odc-by: ODC-By-1.0 Attribution License'
        expect(license_node['xlink:href']).to eq 'https://opendatacommons.org/licenses/by/1-0/'
      end
    end

    context 'when the machine node has a value of none' do
      before do
        obj.rightsMetadata.content = <<~XML
          <rightsMetadata>
            <use>
              <machine type="creativeCommons">none</machine>
            </use>
          </rightsMetadata>
        XML
      end

      it 'does not add license accessConditions and does not alert HB' do
        expect(license_node).to be_nil
        expect(Honeybadger).not_to receive(:notify)
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

    context 'when the rightsMetadata has empty nodes' do
      let(:blank_rights_xml) do
        <<-XML
        <rightsMetadata>
          <copyright>
            <human type="copyright"></human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction" />
            <machine type="creativeCommons">by-nc</machine>
            <human type="creativeCommons"></human>
          </use>
        </rightsMetadata>
        XML
      end

      before do
        obj.rightsMetadata.content = blank_rights_xml
      end

      it 'does not add empty mods nodes' do
        expect(public_mods.xpath('//mods:accessCondition[@type="useAndReproduction"]').size).to eq 0
        expect(public_mods.xpath('//mods:accessCondition[@type="copyright"]').size).to eq 0
      end
    end
  end

  describe 'add_collection_reference' do
    let(:collection) { instantiate_fixture('druid:bc123df4567', Dor::Item) }

    before do
      allow(obj).to receive(:relationships).with(:is_member_of).and_return(['info:fedora/druid:zb871zd0767'])
      allow(obj).to receive(:relationships).with(:is_member_of_collection).and_return(['info:fedora/druid:zb871zd0767'])
      allow(obj).to receive(:relationships).with(:is_constituent_of).and_return([])
      allow(Settings.stacks).to receive(:document_cache_host).and_return('purl.stanford.edu')

      allow(Dor).to receive(:find) do |pid|
        pid == 'druid:ab123cd4567' ? obj : collection
      end
    end

    describe 'relatedItem' do
      let(:mods) { read_fixture('ex2_related_mods.xml') }
      let(:collection_mods) { read_fixture('ex1_mods.xml') }

      before do
        obj.descMetadata.content = mods
        collection.descMetadata.content = collection_mods
      end

      let(:public_mods) { service.ng_xml }

      context 'if the item is a member of a collection' do
        before do
          obj.descMetadata.ng_xml.search('//mods:relatedItem/mods:typeOfResource[@collection=\'yes\']').each do |node|
            node.parent.remove
          end
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
        before do
          allow(obj).to receive(:relationships).with(:is_member_of).and_return([])
          allow(obj).to receive(:relationships).with(:is_member_of_collection).and_return([])
          allow(obj).to receive(:relationships).with(:is_constituent_of).and_return([])
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
        before do
          allow(obj).to receive(:relationships).with(:is_member_of).and_return([non_existent_druid])
          allow(obj).to receive(:relationships).with(:is_member_of_collection).and_return([non_existent_druid])
          allow(obj).to receive(:relationships).with(:is_constituent_of).and_return([])
        end

        let(:non_existent_druid) { 'druid:doesnotexist' }

        before do
          allow(Dor).to receive(:find).with(non_existent_druid).and_raise(ActiveFedora::ObjectNotFoundError)
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
