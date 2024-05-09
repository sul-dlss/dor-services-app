# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicDescMetadataService do
  subject(:service) { described_class.new(item.to_cocina, constituents) }

  let(:constituents) { [] }

  let(:access) { {} }
  let(:identification) { { sourceId: 'sul:123' } }
  let(:structural) { {} }
  let(:description) do
    { title: [{ value: 'stuff' }], purl: 'https://purl.stanford.edu/bc123df4567' }
  end
  let(:item) do
    build(:ar_dro, external_identifier: 'druid:bc123df4567',
                   access:,
                   structural:,
                   description:,
                   identification:)
  end

  describe '#ng_xml' do
    subject(:doc) { service.ng_xml }

    context 'when it is a member of a collection' do
      let(:structural) { { isMemberOf: ['druid:xh235dd9059'] } }

      let(:collection) do
        build(:collection,
              id: 'druid:xh235dd9059',
              title: 'David Rumsey Map Collection at Stanford University Libraries')
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with('druid:xh235dd9059').and_return(collection)
      end

      it 'writes the relationships into MODS' do
        # test that we have 2 expansions
        expect(doc.xpath('//xmlns:mods/xmlns:relatedItem[@type="host"]').size).to eq(1)

        # test the validity of the collection expansion
        xpath_expr = '//xmlns:mods/xmlns:relatedItem[@type="host" and not(@displayLabel)]/xmlns:titleInfo/xmlns:title'
        expect(doc.xpath(xpath_expr).first.text.strip).to eq('David Rumsey Map Collection at Stanford University Libraries')
        xpath_expr = '//xmlns:mods/xmlns:relatedItem[@type="host" and not(@displayLabel)]/xmlns:location/xmlns:url'
        expect(doc.xpath(xpath_expr).first.text.strip).to match(%r{^https?://purl.*\.stanford\.edu/xh235dd9059$})
      end
    end

    context 'with isConstituentOf relationships' do
      let(:constituents) { [{ id: 'druid:hj097bm8879', title: 'Test DRO' }] }

      it 'writes the relationships into MODS' do
        # test that we have 2 expansions
        expect(doc.xpath('//xmlns:mods/xmlns:relatedItem[@type="host"]').size).to eq(1)

        # test the validity of the constituent expansion
        xpath_expr = '//xmlns:mods/xmlns:relatedItem[@type="host" and @displayLabel="Appears in"]/xmlns:titleInfo/xmlns:title'
        expect(doc.xpath(xpath_expr).first.text.strip).to eq('Test DRO')
        xpath_expr = '//xmlns:mods/xmlns:relatedItem[@type="host" and @displayLabel="Appears in"]/xmlns:location/xmlns:url'
        expect(doc.xpath(xpath_expr).first.text.strip).to match(%r{^https://purl.*\.stanford\.edu/hj097bm8879$})
      end
    end

    context 'when the object is a collection' do
      let(:cocina_object) do
        build(:collection, id: 'druid:bc123df4567').new(
          description:,
          identification:
        )
      end

      it 'has no errors' do
        expect { doc }.not_to raise_error
      end
    end
  end

  describe '#to_xml' do
    subject(:xml) { service.to_xml }

    let(:cocina_collection) do
      build(:collection,
            id: 'druid:zb871zd0767',
            title: 'The complete works of Henry George')
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

    context 'with descriptive metadata' do
      let(:abstract_text) do
        "This is a test abstract with line breaks and some links, such as https://sdr-stage.stanford.edu/\r\n\r\nThis is a second line without any links.\r\n\r\nThis is a third line with a link -- https://sdr-stage.stanford.edu/ -- in the middle of a line."
      end
      let(:description) do
        { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
          purl: 'https://purl.stanford.edu/bc123df4567',
          form: [{ value: 'still image', type: 'resource type',
                   source: { value: 'MODS resource types' } },
                 { value: 'photographs, color transparencies', type: 'form' }],
          identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055' }],
          relatedResource: [{ access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] }, type: 'part of' }],
          access: { accessContact: [{ value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }],
                    note: [{ value: 'Property rights reside with the repository.' }] },
          note: [{ value: abstract_text,
                   type: 'abstract' }] }
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

      it 'normalizes carriage returns in the returned string' do
        expect(xml).to include(abstract_text)
      end
    end
  end

  describe '#add_doi' do
    let(:identification) { { doi: '10.80343/ty606df5808', sourceId: 'sul:123' } }

    let(:public_mods) do
      service.ng_xml
    end

    it 'adds the doi in identityMetadata' do
      expect(public_mods.xpath('//xmlns:identifier[@type="doi"]').to_xml).to eq(
        '<identifier type="doi" displayLabel="DOI">https://doi.org/10.80343/ty606df5808</identifier>'
      )
    end
  end

  describe '#add_access_conditions' do
    subject(:public_mods) do
      service.ng_xml
    end

    let(:access) do
      {
        copyright: 'Property rights reside with the repository. Copyright &#xA9; Stanford University. All Rights Reserved.',
        useAndReproductionStatement: 'Image from the Glen McLaughlin Map Collection yada ...',
        license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
      }
    end

    let(:license_node) { public_mods.xpath('//xmlns:accessCondition[@type="license"]').first }

    it 'adds useAndReproduction accessConditions' do
      expect(public_mods.xpath('//xmlns:accessCondition[@type="useAndReproduction"]').size).to eq 1
      expect(public_mods.xpath('//xmlns:accessCondition[@type="useAndReproduction"]').text).to match(/yada/)
    end

    it 'adds copyright accessConditions' do
      expect(public_mods.xpath('//xmlns:accessCondition[@type="copyright"]').size).to eq 1
      expect(public_mods.xpath('//xmlns:accessCondition[@type="copyright"]').text).to match(/Property rights reside with/)
    end

    it 'adds license accessConditions' do
      expect(public_mods.xpath('//xmlns:accessCondition[@type="license"]').size).to eq 1
      expect(license_node.text).to eq 'This work is licensed under a Creative Commons Attribution Non Commercial 3.0 Unported license (CC BY-NC).'
      expect(public_mods.root.namespaces).to include('xmlns:xlink')
      expect(license_node['xlink:href']).to eq 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
    end

    context 'when there are existing access conditions' do
      let(:description) do
        {
          title: [{ value: 'stuff' }],
          purl: 'https://purl.stanford.edu/bc123df4567',
          access: {
            note: [
              {
                value: 'Available to Stanford researchers only.',
                type: 'access restriction'
              }
            ]
          }
        }
      end

      it 'removes any pre-existing accessConditions already in the mods' do
        expect(public_mods.xpath('//xmlns:accessCondition').size).to eq 3
        expect(public_mods.xpath('//xmlns:accessCondition[text()[contains(.,"Stanford researchers")]]')).to be_empty
      end
    end
  end

  describe 'add_collection_reference' do
    let(:structural) { { isMemberOf: ['druid:zb871zd0767'] } }

    let(:collection) do
      build(:collection, id: 'druid:zb871zd0767').new(
        description: {
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
        }
      )
    end

    before do
      allow(CocinaObjectStore).to receive(:find).with('druid:zb871zd0767').and_return(collection)
      allow(Settings.stacks).to receive(:document_cache_host).and_return('purl.stanford.edu')
    end

    describe 'relatedItem' do
      let(:public_mods) { service.ng_xml }

      context 'when the item is a member of a collection' do
        let(:description) do
          { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
            purl: 'https://purl.stanford.edu/bc123df4567',
            form: [{ value: 'still image', type: 'resource type',
                     source: { value: 'MODS resource types' } },
                   { value: 'photographs, color transparencies', type: 'form' }],
            identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055' }],
            relatedResource: [{ access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] }, type: 'part of' }],
            access: { accessContact: [{ value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }],
                      note: [{ value: 'Property rights reside with the repository.' }] } }
        end

        it 'adds a relatedItem node for the collection' do
          collections      = public_mods.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
          collection_uri   = public_mods.search('//xmlns:relatedItem/xmlns:location/xmlns:url')
          expect(collections.length).to eq 1
          expect(collection_title.length).to eq 1
          expect(collection_uri.length).to eq 1
          expect(collection_title.first.content).to eq 'The complete works of Henry George'
          expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
        end
      end

      it 'replaces an existing relatedItem if there is a parent collection with title' do
        collections      = public_mods.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
        collection_title = public_mods.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
        collection_uri   = public_mods.search('//xmlns:relatedItem/xmlns:location/xmlns:url')
        expect(collections.length).to eq 1
        expect(collection_title.length).to eq 1
        expect(collection_uri.length).to eq 1
        expect(collection_title.first.content).to eq 'The complete works of Henry George'
        expect(collection_uri.first.content).to eq 'https://purl.stanford.edu/zb871zd0767'
      end

      context 'if there is no collection relationship' do
        let(:structural) { { isMemberOf: [] } }

        let(:description) do
          { title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
            purl: 'https://purl.stanford.edu/bc123df4567',
            form: [{ value: 'still image', type: 'resource type',
                     source: { value: 'MODS resource types' } }, { value: 'photographs, color transparencies', type: 'form' }],
            identifier: [{ displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055' }],
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
          collections      = public_mods.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
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
          collections      = public_mods.search('//xmlns:relatedItem/xmlns:typeOfResource[@collection=\'yes\']')
          collection_title = public_mods.search('//xmlns:relatedItem/xmlns:titleInfo/xmlns:title')
          collection_uri   = public_mods.search('//xmlns:relatedItem/xmlns:location/xmlns:url')
          expect(collections.length).to eq 0
          expect(collection_title.length).to eq 0
          expect(collection_uri.length).to eq 0
        end
      end
    end
  end
end
