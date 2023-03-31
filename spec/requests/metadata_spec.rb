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
end
