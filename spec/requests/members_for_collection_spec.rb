# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the members' do
  before do
    allow(ActiveFedora::SolrService.instance.conn).to receive(:get).and_return(solr_response)
  end

  let(:druid) { 'druid:mk420bs7601' }

  let(:solr_params) do
    {
      fl: 'id,objectType_ssim',
      q: "is_member_of_collection_ssim:\"#{ActiveFedora::Base.internal_uri(druid)}\" published_dttsim:[* TO *]",
      rows: 100_000_000,
      wt: :json
    }
  end

  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          { 'id' => 'druid:xx222xx3282', 'objectType_ssim' => 'collection' },
          { 'id' => 'druid:xx828xx3282', 'objectType_ssim' => 'item' }
        ]
      }
    }
  end

  let(:expected) do
    {
      members: [
        {
          externalIdentifier: 'druid:xx222xx3282',
          type: 'collection'
        },
        {
          externalIdentifier: 'druid:xx828xx3282',
          type: 'item'
        }
      ]
    }
  end

  let(:response_model) { JSON.parse(response.body).deep_symbolize_keys }

  it 'sends the correct solr params, returns the druid & type of the members' do
    get "/v1/objects/#{druid}/members",
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(ActiveFedora::SolrService.instance.conn).to have_received(:get).with('select', params: solr_params)
    expect(response).to be_successful
    expect(response_model).to eq expected
  end
end
