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
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end
  let(:structural) do
    {
      contains: [{
        type: Cocina::Models::Vocab::Resources.image,
        externalIdentifier: 'wt183gy6220',
        label: 'Image 1',
        version: 1,
        structural: {
          contains: [{
            type: Cocina::Models::Vocab.file,
            externalIdentifier: 'wt183gy6220_1',
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
      }]
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

    let(:rels) do
      <<-EOXML
            <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
              <rdf:Description rdf:about="info:fedora/druid:bc123df4567">
                <hydra:isGovernedBy rdf:resource="info:fedora/druid:789012"></hydra:isGovernedBy>
                <fedora-model:hasModel rdf:resource="info:fedora/hydra:commonMetadata"></fedora-model:hasModel>
                <fedora:isMemberOf rdf:resource="info:fedora/druid:xh235dd9059"></fedora:isMemberOf>
                <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"></fedora:isMemberOfCollection>
                <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"></fedora:isConstituentOf>
              </rdf:Description>
            </rdf:RDF>
      EOXML
    end
    let(:ng_xml) { Nokogiri::XML(xml) }

    let(:rights) do
      <<~XML
        <rightsMetadata objectId="druid:bc123df4567">
          <copyright>
            <human>(c) Copyright 2010 by Sebastian Jeremias Osterfeld</human>
          </copyright>
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
      XML
    end

    before do
      mods = <<-EOXML
        <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   version="3.3"
                   xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cosimo.stanford.edu/standards/mods/v3/mods-3-3.xsd">
          <mods:identifier type="local" displayLabel="SUL Resource ID">druid:bc123df4567</mods:identifier>
        </mods:mods>
      EOXML

      item.contentMetadata.content = '<contentMetadata/>'
      item.descMetadata.content    = mods
      item.rightsMetadata.content  = rights
      item.rels_ext.content        = rels
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
                                  embargo: {
                                    releaseDate: DateTime.parse('2050-05-31')
                                  }
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:result) do
        ng_xml.at_xpath('/publicObject/rightsMetadata/access[@type="read"]/machine/embargoReleaseDate').text
      end

      it 'adds embargo to the rights' do
        expect(result).to eq '2050-05-31T00:00:00Z'
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

      describe 'with contentMetadata present' do
        before do
          item.contentMetadata.content = <<-XML
            <?xml version="1.0"?>
            <contentMetadata objectId="druid:bc123df4567" type="file">
              <resource id="0001" sequence="1" type="file">
                <file id="some_file.pdf" mimetype="file/pdf" publish="yes"/>
              </resource>
            </contentMetadata>
          XML
        end

        it 'include contentMetadata' do
          expect(ng_xml.at_xpath('/publicObject/contentMetadata')).to be
        end
      end

      it 'generated mods' do
        expect(ng_xml.at_xpath('/publicObject/mods:mods', 'mods' => 'http://www.loc.gov/mods/v3')).to be
      end

      it 'generated dublin core' do
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc',
                               'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
      end

      it 'relationships' do
        ns = {
          'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'hydra' => 'http://projecthydra.org/ns/relations#',
          'fedora' => 'info:fedora/fedora-system:def/relations-external#',
          'fedora-model' => 'info:fedora/fedora-system:def/model#'
        }
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF', ns)).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora:isMemberOf', ns)).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora:isMemberOfCollection', ns)).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora:isConstituentOf', ns)).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/fedora-model:hasModel', ns)).not_to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF/rdf:Description/hydra:isGovernedBy', ns)).not_to be
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
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end

      it 'publishes the expected datastreams' do
        expect(ng_xml.at_xpath('/publicObject/identityMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/rightsMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/mods:mods', 'mods' => 'http://www.loc.gov/mods/v3')).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')).to be
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc',
                               'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
      end
    end

    context 'with external references' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end

      it 'handles externalFile references' do
        correct_content_md = Nokogiri::XML(read_fixture('hj097bm8879_publicObject.xml')).at_xpath('/publicObject/contentMetadata').to_xml
        item.contentMetadata.content = read_fixture('hj097bm8879_contentMetadata.xml')

        cover_item = instantiate_fixture('druid:cg767mn6478', Dor::Item)
        allow(Dor).to receive(:find).with(cover_item.pid).and_return(cover_item)
        title_item = instantiate_fixture('druid:jw923xn5254', Dor::Item)
        allow(Dor).to receive(:find).with(title_item.pid).and_return(title_item)

        # generate publicObject XML and verify that the content metadata portion is correct and the correct thumb is present
        expect(ng_xml.at_xpath('/publicObject/contentMetadata').to_xml).to be_equivalent_to(correct_content_md)
        expect(ng_xml.at_xpath('/publicObject/thumb').to_xml).to be_equivalent_to('<thumb>bc123df4567/wt183gy6220_00_0001.jp2</thumb>')
      end

      context 'when the referenced object does not have the referenced resource' do
        let(:cover_item) { instance_double(Dor::Item, pid: 'druid:cg767mn6478', contentMetadata: contentMetadata) }
        let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, ng_xml: Nokogiri::XML(cm_xml)) }
        let(:cm_xml) do
          <<-EOXML
          <contentMetadata objectId="cg767mn6478" type="map">
          </contentMetadata>
          EOXML
        end

        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1" />
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML

          allow(Dor).to receive(:find).with(cover_item.pid).and_return(cover_item)
        end

        it 'raises an error' do
          expect do
            xml
          end.to raise_error(Dor::DataError, 'The contentMetadata of druid:bc123df4567 has an externalFile ' \
                                             "reference to druid:cg767mn6478, cg767mn6478_1, but druid:cg767mn6478 doesn't have " \
                                             'a matching resource node in its contentMetadata')
        end
      end

      context 'when the referenced object does not have the referenced image' do
        let(:cover_item) { instance_double(Dor::Item, pid: 'druid:cg767mn6478', contentMetadata: contentMetadata) }
        let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, ng_xml: Nokogiri::XML(cm_xml)) }
        let(:cm_xml) do
          <<-EOXML
          <contentMetadata objectId="cg767mn6478" type="map">
            <resource id="cg767mn6478_1" sequence="1" type="image">
            </resource>
          </contentMetadata>
          EOXML
        end

        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1" />
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML

          allow(Dor).to receive(:find).with(cover_item.pid).and_return(cover_item)
        end

        it 'raises an error' do
          expect do
            xml
          end.to raise_error(Dor::DataError,
                             'Unable to find a file node with id="2542A.jp2" (child of druid:bc123df4567)')
        end
      end

      context 'when it is missing resourceId and mimetype attributes' do
        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478"/>
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML
        end

        it 'raises an error' do
          # generate publicObject XML and verify that the content metadata portion is invalid
          expect { xml }.to raise_error(Dor::DataError)
        end
      end

      context 'when it has blank resourceId attribute' do
        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId="2542A.jp2" objectId="druid:cg767mn6478" resourceId=" " mimetype="image/jp2"/>
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML
        end

        it 'raises an error' do
          # generate publicObject XML and verify that the content metadata portion is invalid
          expect { xml }.to raise_error(Dor::DataError)
        end
      end

      context 'when it has blank fileId attribute' do
        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId=" " objectId="druid:cg767mn6478" resourceId="cg767mn6478_1" mimetype="image/jp2"/>
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML
        end

        it 'raises an error' do
          # generate publicObject XML and verify that the content metadata portion is invalid
          expect { xml }.to raise_error(Dor::DataError)
        end
      end

      context 'when it has blank objectId attribute' do
        before do
          item.contentMetadata.content = <<-EOXML
          <contentMetadata objectId="hj097bm8879" type="map">
            <resource id="hj097bm8879_1" sequence="1" type="image">
              <externalFile fileId="2542A.jp2" objectId=" " resourceId="cg767mn6478_1" mimetype="image/jp2"/>
              <relationship objectId="druid:cg767mn6478" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
          EOXML
        end

        it 'raises an error' do
          # generate publicObject XML and verify that the content metadata portion is invalid
          expect { xml }.to raise_error(Dor::DataError)
        end
      end
    end

    context 'with a cocina-originating object' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end

      before do
        item.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="http://cocina.sul.stanford.edu/fileSet/7bf4cfb1-7e29-4f27-b865-79e10a77f29e" sequence="1" type="file">
              <file id="some_file.pdf" mimetype="file/pdf" publish="yes"/>
            </resource>
          </contentMetadata>
        XML
      end

      it 'cleans up the resource id to be XML-valid' do
        expect(ng_xml.at_xpath('/publicObject/contentMetadata/resource[1]')['id']).to eq 'cocina-fileSet-7bf4cfb1-7e29-4f27-b865-79e10a77f29e'
      end
    end
  end
end
