# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicXmlService do
  subject(:service) { described_class.new(item, released_for: release_tags) }

  let(:release_tags) { {} }

  let(:item) { instantiate_fixture('druid:bc123df4567', Dor::Item) }

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

    let(:ng_xml) { Nokogiri::XML(xml) }

    context 'when there are no release tags' do
      let(:release_tags) { {} }

      it 'does not include a releaseData element and any info in identityMetadata' do
        expect(ng_xml.at_xpath('/publicObject/releaseData')).to be_nil
        expect(ng_xml.at_xpath('/publicObject/identityMetadata/release')).to be_nil
      end
    end

    context 'with an embargo' do
      let(:embargo) do
        <<~XML
          <embargoMetadata>
            <status>embargoed</status>
            <releaseDate>2021-10-08T00:00:00Z</releaseDate>
            <twentyPctVisibilityStatus/>
            <twentyPctVisibilityReleaseDate/>
            <releaseAccess>
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
            </releaseAccess>
          </embargoMetadata>
        XML
      end

      let(:result) do
        ng_xml.at_xpath('/publicObject/rightsMetadata/access[@type="read"]/machine/embargoReleaseDate').text
      end

      before do
        item.embargoMetadata.content = embargo
      end

      it 'adds embargo to the rights' do
        expect(result).to eq '2021-10-08T00:00:00Z'
      end
    end

    context 'produces xml with' do
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
        expect(ng_xml.at_xpath('/publicObject/@publishVersion').value).to eq('dor-services/' + Dor::VERSION)
      end

      it 'identityMetadata' do
        expect(ng_xml.at_xpath('/publicObject/identityMetadata')).to be
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
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc', 'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
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

      it 'clones of the content of the other datastreams, keeping the originals in tact' do
        expect(item.datastreams['identityMetadata'].ng_xml.at_xpath('/identityMetadata')).to be
        expect(item.datastreams['contentMetadata'].ng_xml.at_xpath('/contentMetadata')).to be
        expect(item.datastreams['rightsMetadata'].ng_xml.at_xpath('/rightsMetadata')).to be
        expect(item.datastreams['RELS-EXT'].content).to be_equivalent_to rels
      end

      it 'does not add a thumb node if no thumb is present' do
        expect(ng_xml.at_xpath('/publicObject/thumb')).not_to be
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
        expect(ng_xml.at_xpath('/publicObject/thumb').to_xml).to be_equivalent_to('<thumb>bc123df4567/bc123df4567_05_0002.jp2</thumb>')
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
      it 'publishes the expected datastreams' do
        expect(ng_xml.at_xpath('/publicObject/identityMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/rightsMetadata')).to be
        expect(ng_xml.at_xpath('/publicObject/mods:mods', 'mods' => 'http://www.loc.gov/mods/v3')).to be
        expect(ng_xml.at_xpath('/publicObject/rdf:RDF', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')).to be
        expect(ng_xml.at_xpath('/publicObject/oai_dc:dc', 'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/')).to be
      end
    end

    context 'with external references' do
      it 'handles externalFile references' do
        correct_content_md = Nokogiri::XML(read_fixture('hj097bm8879_publicObject.xml')).at_xpath('/publicObject/contentMetadata').to_xml
        item.contentMetadata.content = read_fixture('hj097bm8879_contentMetadata.xml')

        cover_item = instantiate_fixture('druid:cg767mn6478', Dor::Item)
        allow(Dor).to receive(:find).with(cover_item.pid).and_return(cover_item)
        title_item = instantiate_fixture('druid:jw923xn5254', Dor::Item)
        allow(Dor).to receive(:find).with(title_item.pid).and_return(title_item)

        # generate publicObject XML and verify that the content metadata portion is correct and the correct thumb is present
        expect(ng_xml.at_xpath('/publicObject/contentMetadata').to_xml).to be_equivalent_to(correct_content_md)
        expect(ng_xml.at_xpath('/publicObject/thumb').to_xml).to be_equivalent_to('<thumb>jw923xn5254/2542B.jp2</thumb>')
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
          expect { xml }.to raise_error(Dor::DataError, 'The contentMetadata of druid:bc123df4567 has an externalFile ' \
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
          expect { xml }.to raise_error(Dor::DataError, 'Unable to find a file node with id="2542A.jp2" (child of druid:bc123df4567)')
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
  end
end
