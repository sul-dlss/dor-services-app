# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Display metadata' do
  let(:description) do
    {
      title: [{ value: 'Hello' }],
      purl: 'https://purl.stanford.edu/mk420bs7601'
    }
  end
  let(:cocina_object) do
    build(:dro, id: 'druid:mk420bs7601').new(description:)
  end

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
  end

  describe 'dublin core' do
    before do
      allow(SolrService.instance).to receive(:conn).and_return(solr_client)
    end

    let(:solr_client) { instance_double(RSolr::Client, get: solr_response) }
    let(:solr_response) { { 'response' => { 'docs' => virtual_object_solr_docs } } }
    let(:virtual_object_solr_docs) { [] }

    it 'returns the DC xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/dublin_core',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to include '<dc:title>Hello</dc:title>'
    end
  end

  describe 'mods' do
    it 'returns the source MODS xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/mods',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
          <titleInfo>
            <title>Hello</title>
          </titleInfo>
          <location>
            <url usage="primary display">https://purl.stanford.edu/mk420bs7601</url>\n
          </location>
        </mods>
      XML
    end
  end

  describe 'descriptive' do
    before do
      allow(SolrService.instance).to receive(:conn).and_return(solr_client)
    end

    let(:solr_client) { instance_double(RSolr::Client, get: solr_response) }
    let(:solr_response) { { 'response' => { 'docs' => virtual_object_solr_docs } } }
    let(:virtual_object_solr_docs) { [] }

    it 'returns the public descriptive metadata xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/descriptive',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
          <titleInfo>
            <title>Hello</title>
          </titleInfo>
          <location>
            <url usage="primary display">https://purl.stanford.edu/mk420bs7601</url>\n
          </location>\n
        </mods>
      XML
    end
  end

  describe 'public_xml' do
    let(:now) { Time.now } # rubocop:disable Rails/TimeZone
    let(:relationships_xml) do
      <<~XML
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#">
          <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
            <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"/>
            <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"/>
          </rdf:Description>
        </rdf:RDF>
      XML
    end

    let(:solr_client) { instance_double(RSolr::Client, get: solr_response) }
    let(:solr_response) { { 'response' => { 'docs' => virtual_object_solr_docs } } }
    let(:virtual_object_solr_docs) { [] }

    before do
      allow(SolrService.instance).to receive(:conn).and_return(solr_client)

      allow(ReleaseTags).to receive(:for).and_return(
        'SearchWorks' => { 'release' => true },
        'elsewhere' => { 'release' => false }
      )
      allow(Time).to receive(:now).and_return(now)
      allow_any_instance_of(PublishedRelationshipsFilter).to receive(:xml).and_return(relationships_xml)
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    end

    it 'returns the full public xml representation' do
      get '/v1/objects/druid:mk420bs7601/metadata/public_xml',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <publicObject id="druid:mk420bs7601" published="#{now.utc.xmlschema}" publishVersion="cocina-models/#{Cocina::Models::VERSION}">
          <identityMetadata>
            <objectType>item</objectType>
            <objectLabel>Hello</objectLabel>
            <sourceId source="sul">sul:1234</sourceId>
          </identityMetadata>
          <rightsMetadata>
            <access type="discover">
              <machine>
                <none/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
          #{relationships_xml}
          <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:srw_dc="info:srw/schema/1/dc-schema" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
            <dc:title>Hello</dc:title>
            <dc:identifier>https://purl.stanford.edu/mk420bs7601</dc:identifier>
          </oai_dc:dc>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
            <titleInfo>
              <title>Hello</title>
            </titleInfo>
            <location>
              <url usage="primary display">https://purl.stanford.edu/mk420bs7601</url>
            </location>
          </mods>
          <releaseData>
            <release to="SearchWorks">true</release>
            <release to="elsewhere">false</release>
          </releaseData>
        </publicObject>
      XML
    end
  end
end
