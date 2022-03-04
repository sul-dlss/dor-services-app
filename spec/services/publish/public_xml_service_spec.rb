# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicXmlService do
  subject(:service) do
    described_class.new(public_cocina: public_cocina,
                        released_for: release_tags,
                        thumbnail_service: thumbnail_service)
  end

  let(:public_cocina) { Publish::PublicCocinaService.create(cocina_object) }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }
  let(:description) do
    {
      title: [{ value: 'Constituent label &amp; A Special character' }],
      purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
    }
  end
  let(:structural) do
    {
      contains: [{
        type: Cocina::Models::Vocab::Resources.image,
        externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/9475bc2c-7552-43d8-b8ab-8cd2212d5873',
        label: 'Image 1',
        version: 1,
        structural: {
          contains: [{
            type: Cocina::Models::Vocab.file,
            externalIdentifier: 'http://cocina.sul.stanford.edu/file/15e6e501-d22c-4f96-a824-8a88dd312937',
            label: 'Image 1',
            filename: 'wt183gy6220_00_0001.jp2',
            hasMimeType: 'image/jp2',
            size: 3_182_927,
            version: 1,
            access: {},
            administrative: {
              publish: false,
              sdrPreserve: false,
              shelve: false
            },
            hasMessageDigests: []
          }]
        }
      }],
      isMemberOf: ['druid:xh235dd9059']
    }
  end
  let(:release_tags) { {} }

  let(:druid) { 'druid:bc123df4567' }
  let(:item) { instantiate_fixture('druid:bc123df4567', Dor::Item) }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
  end

  describe '#to_xml' do
    subject(:xml) { service.to_xml }

    let(:ng_xml) { Nokogiri::XML(xml) }

    before do
      mods = <<-EOXML
        <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   version="3.3"
                   xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cosimo.stanford.edu/standards/mods/v3/mods-3-3.xsd">
          <mods:identifier type="local" displayLabel="SUL Resource ID">druid:bc123df4567</mods:identifier>
        </mods:mods>
      EOXML

      allow(VirtualObject).to receive(:for).and_return([{ id: 'druid:hj097bm8879' }])
      item.contentMetadata.content = '<contentMetadata/>'
      item.descMetadata.content    = mods
      allow_any_instance_of(Publish::PublicDescMetadataService).to receive(:ng_xml).and_return(Nokogiri::XML(mods)) # calls Item.find and not needed in general tests
      allow(OpenURI).to receive(:open_uri).with('https://purl-test.stanford.edu/bc123df4567.xml').and_return('<xml/>')
      WebMock.disable_net_connect!
    end

    context 'when there are no release tags' do
      let(:release_tags) { {} }
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      it 'does not include a releaseData element and any info in identityMetadata' do
        expect(ng_xml.at_xpath('/publicObject/releaseData')).to be_nil
        expect(ng_xml.at_xpath('/publicObject/identityMetadata/release')).to be_nil
      end
    end

    context 'with an embargo' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world',
                                  embargo: {
                                    releaseDate: '2021-10-08T00:00:00Z'
                                  }
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:result) do
        ng_xml.at_xpath('/publicObject/rightsMetadata/access[@type="read"]/machine/embargoReleaseDate').text
      end

      it 'adds embargo to the rights' do
        expect(result).to eq '2021-10-08T00:00:00Z'
      end
    end

    context 'with an problematic location code' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'location-based',
                                  download: 'location-based',
                                  readLocation: 'm&m'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:result) do
        ng_xml.at_xpath('/publicObject/rightsMetadata/access[@type="read"]/machine/location').text
      end

      it 'does not munge the location code' do
        expect(result).to eq 'm&m'
      end
    end

    context 'produces xml with' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {
                                  catalogLinks: [
                                    { catalog: 'previous symphony', catalogRecordId: '9001001001' },
                                    { catalog: 'symphony', catalogRecordId: '129483625' }
                                  ]
                                },
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end
      let(:now) { Time.now.utc }

      before do
        allow(Time).to receive(:now).and_return(now)
      end

      it 'an encoding of UTF-8' do
        expect(ng_xml.encoding).to match(/UTF-8/)
      end

      it 'an id attribute' do
        expect(ng_xml.at_xpath('/publicObject/@id').value).to match(/^druid:bc123df4567/)
      end

      it 'a published attribute' do
        expect(ng_xml.at_xpath('/publicObject/@published').value).to eq(now.xmlschema)
      end

      it 'a published version' do
        expect(ng_xml.at_xpath('/publicObject/@publishVersion').value).to eq("dor-services/#{Dor::VERSION}")
      end

      it 'has identityMetadata with catkeys' do
        expected = <<~XML
          <identityMetadata>
            <objectType>item</objectType>
            <objectLabel>A generic label</objectLabel>
            <otherId name="catkey">129483625</otherId>
          </identityMetadata>
        XML
        expect(ng_xml.at_xpath('/publicObject/identityMetadata').to_xml).to be_equivalent_to expected
      end

      it 'no contentMetadata element' do
        expect(ng_xml.at_xpath('/publicObject/contentMetadata')).not_to be
      end

      describe 'with structural metadata that has a published file' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::Vocab::Resources.image,
              externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/9475bc2c-7552-43d8-b8ab-8cd2212d5873',
              label: 'Image 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::Vocab.file,
                  externalIdentifier: 'http://cocina.sul.stanford.edu/file/15e6e501-d22c-4f96-a824-8a88dd312937',
                  label: 'Image 1',
                  filename: 'wt183gy6220_00_0001.jp2',
                  hasMimeType: 'image/jp2',
                  size: 3_182_927,
                  version: 1,
                  access: {},
                  administrative: {
                    publish: true,
                    sdrPreserve: false,
                    shelve: false
                  },
                  hasMessageDigests: []
                }]
              }
            }]
          }
        end

        it 'rewrites the resource id so it can be used as a URI component' do
          expect(ng_xml.at_xpath('/publicObject/contentMetadata/resource[1]')['id']).to eq 'cocina-fileSet-bc123df4567-9475bc2c-7552-43d8-b8ab-8cd2212d5873'
        end
      end

      it 'generated mods' do
        expect(ng_xml.at_xpath('/publicObject/mods:mods', 'mods' => 'http://www.loc.gov/mods/v3')).to be
      end

      it 'generated dublin core' do
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc', 'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
      end

      it 'exports relationships' do
        ns = {
          'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'fedora' => 'info:fedora/fedora-system:def/relations-external#'
        }
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora:isMemberOfCollection', ns)).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora:isConstituentOf', ns)).to be
      end

      context 'when no thumb is present' do
        let(:cocina_object) do
          Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A generic label',
                                  version: 1,
                                  description: description,
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
        end

        it 'does not add a thumb node' do
          expect(ng_xml.at_xpath('/publicObject/thumb')).not_to be
        end
      end

      it 'include a thumb node if a thumb is present' do
        item.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="map">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="image">
              <file id="bc123df4567_05_0002.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(ng_xml.at_xpath('/publicObject/thumb').to_xml).to be_equivalent_to('<thumb>bc123df4567/wt183gy6220_00_0001.jp2</thumb>')
      end

      context 'when there is content inside it' do
        let(:release_tags) do
          { 'Searchworks' => { 'release' => true }, 'Some_special_place' => { 'release' => true } }
        end

        it 'does not include this release data in identityMetadata' do
          expect(ng_xml.at_xpath('/publicObject/identityMetadata/release')).to be_nil
        end

        it 'includes releaseData element from release tags' do
          releases = ng_xml.xpath('/publicObject/releaseData/release')
          expect(releases.map(&:inner_text)).to eq %w[true true]
          expect(releases.map { |r| r['to'] }).to eq %w[Searchworks Some_special_place]
        end
      end
    end

    context 'with a collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'A generic label',
                                       version: 1,
                                       description: description,
                                       identification: {},
                                       access: {},
                                       administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      it 'publishes the expected datastreams' do
        expect(ng_xml.at_xpath('/publicObject/identityMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/rightsMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/mods:mods', 'mods' => 'http://www.loc.gov/mods/v3')).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')).to be
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc', 'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
      end
    end

    context 'with external references' do
      let(:druid) { 'druid:hj097bm8879' }
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: druid,
                                type: Cocina::Models::Vocab.map,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end
      let(:structural) do
        {
          hasMemberOrders: [
            {
              members: ['druid:cg767mn6478', 'druid:jw923xn5254']
            }
          ]
        }
      end

      let(:cover_item) do
        Cocina::Models::DRO.new(
          { cocinaVersion: '0.65.1',
            type: 'http://cocina.sul.stanford.edu/models/image.jsonld',
            externalIdentifier: 'druid:cg767mn6478',
            label: "Cover: Carey's American atlas.",
            version: 3,
            access: { access: 'world',
                      download: 'world',
                      copyright: 'Property rights reside with the repository, Copyright © Stanford University.',
                      useAndReproductionStatement: 'To obtain permission to publish or reproduce commercially, please contact the Digital & Rare Map Librarian',
                      license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' },
            administrative: {
              hasAdminPolicy: 'druid:sq161jk2248'
            },
            description: {
              title: [{
                value: "(Covers to) Carey's American Atlas: Containing Twenty Maps And One Chart ... Philadelphia: Engraved For, And Published By, Mathew Carey, " \
                       'No. 118, Market Street. M.DCC.XCV. [Price, Plain, Five Dollars-Coloured, Six Dollars.]'
              }, {
                value: "Cover: Carey's American atlas.",
                type: 'alternative',
                displayLabel: 'Short title'
              }],
              purl: 'https://purl.stanford.edu/cg767mn6478'
            },
            identification: { catalogLinks: [],
                              sourceId: 'Rumsey:2542A' },
            structural: {
              contains: [
                {
                  type: 'http://cocina.sul.stanford.edu/models/resources/image.jsonld',
                  externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/9475bc2c-7552-43d8-b8ab-8cd2212d5873',
                  label: 'Image 1',
                  version: 3,
                  structural: {
                    contains: [
                      { type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                        externalIdentifier: 'http://cocina.sul.stanford.edu/file/15e6e501-d22c-4f96-a824-8a88dd312937',
                        label: '2542A.tif',
                        filename: '2542A.tif',
                        size: 92_217_124,
                        version: 3,
                        hasMimeType: 'image/tiff',
                        hasMessageDigests: [
                          { type: 'sha1',
                            digest: '1f09f8796bfa67db97557f3de48a96c87b286d32' },
                          { type: 'md5',
                            digest: '5b79c8570b7ef582735f912aa24ce5f2' }
                        ],
                        access: { access: 'world',
                                  download: 'world' },
                        administrative: { publish: false,
                                          sdrPreserve: true,
                                          shelve: false },
                        presentation: { height: 4747,
                                        width: 6475 } },
                      { type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                        externalIdentifier: 'http://cocina.sul.stanford.edu/file/c59ada47-489b-4d0b-ab28-136b824d3904',
                        label: '2542A.jp2',
                        filename: '2542A.jp2',
                        size: 5_789_764,
                        version: 3,
                        hasMimeType: 'image/jp2',
                        hasMessageDigests: [{ type: 'sha1',
                                              digest: '39feed6ee1b734cab2d6a446e909a9fc7ac6fd01' }, { type: 'md5',
                                                                                                      digest: 'cd5ca5c4666cfd5ce0e9dc8c83461d7a' }],
                        access: { access: 'world',
                                  download: 'world' },
                        administrative: { publish: true,
                                          sdrPreserve: false,
                                          shelve: true },
                        presentation: { height: 4747,
                                        width: 6475 } }
                    ]
                  }
                }
              ]
            } }
        )
      end

      let(:title_item) do
        Cocina::Models::DRO.new(
          { cocinaVersion: '0.65.1',
            type: 'http://cocina.sul.stanford.edu/models/image.jsonld',
            externalIdentifier: 'druid:jw923xn5254',
            label: "Title Page: Carey's American atlas.",
            version: 3,
            access: { access: 'world',
                      download: 'world',
                      copyright: 'Property rights reside with the repository, Copyright © Stanford University.',
                      useAndReproductionStatement: 'To obtain permission to publish or reproduce commercially, please contact the Digital & Rare Map Librarian',
                      license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' },
            administrative: { hasAdminPolicy: 'druid:sq161jk2248',
                              releaseTags: [] },
            description: {
              title: [{
                value: "(Title Page to) Carey's American Atlas: Containing Twenty Maps And One Chart ... Philadelphia: Engraved For, And Published By, Mathew Carey, " \
                       'No. 118, Market Street. M.DCC.XCV. [Price, Plain, Five Dollars-Coloured, Six Dollars.]'
              }, {
                value: "Title Page: Carey's American atlas.",
                type: 'alternative',
                displayLabel: 'Short title'
              }],
              purl: 'https://purl.stanford.edu/jw923xn5254'
            },
            identification: {
              catalogLinks: [],
              sourceId: 'Rumsey:2542B'
            },
            structural: {
              contains: [
                {
                  type: 'http://cocina.sul.stanford.edu/models/resources/image.jsonld',
                  externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/929604b0-00bc-40b1-af71-5c17f066e2fd',
                  label: 'Image 1',
                  version: 3,
                  structural: {
                    contains: [
                      {
                        type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                        externalIdentifier: 'http://cocina.sul.stanford.edu/file/787afaca-ba6e-4998-84bd-1bb43f9182cf',
                        label: '2542B.tif',
                        filename: '2542B.tif',
                        size: 44_028_890,
                        version: 3,
                        hasMimeType: 'image/tiff',
                        hasMessageDigests: [{ type: 'sha1',
                                              digest: 'a90aea983620238d8e1384d9a5cb683c6acd6984' }, { type: 'md5',
                                                                                                      digest: 'b5f6fcd6eb0ad02800aeb82cba6d0eed' }],
                        access: { access: 'world',
                                  download: 'world' },
                        administrative: { publish: false,
                                          sdrPreserve: true,
                                          shelve: false },
                        presentation: { height: 4675,
                                        width: 3139 }
                      },
                      {
                        type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                        externalIdentifier: 'http://cocina.sul.stanford.edu/file/72880460-6865-4aa9-85c7-ac26002aebc5',
                        label: '2542B.jp2',
                        filename: '2542B.jp2',
                        size: 2_762_668,
                        version: 3,
                        hasMimeType: 'image/jp2',
                        hasMessageDigests: [
                          { type: 'sha1',
                            digest: '80454c111675ec7e2c425e909810c49a69ffef26' },
                          { type: 'md5',
                            digest: 'bccdbb2500bb139d6d622321bfd2aa57' }
                        ],
                        access: { access: 'world',
                                  download: 'world' },
                        administrative: { publish: true,
                                          sdrPreserve: false,
                                          shelve: true },
                        presentation: { height: 4675,
                                        width: 3139 }
                      }
                    ]
                  }
                }
              ]
            } }
        )
      end

      it 'handles externalFile references' do
        correct_content_md = Nokogiri::XML(read_fixture('hj097bm8879_publicObject.xml')).at_xpath('/publicObject/contentMetadata').to_xml
        item.contentMetadata.content = read_fixture('hj097bm8879_contentMetadata.xml')

        allow(CocinaObjectStore).to receive(:find).with(cover_item.externalIdentifier).and_return(cover_item)
        allow(CocinaObjectStore).to receive(:find).with(title_item.externalIdentifier).and_return(title_item)
        expect(ng_xml.at_xpath('/publicObject/contentMetadata').to_xml).to be_equivalent_to(correct_content_md)
      end
    end
  end
end
