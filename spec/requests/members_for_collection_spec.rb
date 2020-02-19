# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the members' do
  before do
    allow(ActiveFedora::SolrService.instance.conn).to receive(:get).and_return(solr_response)
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

  it 'returns the druid & type of the members' do
    get '/v1/objects/druid:mk420bs7601/members',
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response_model).to eq expected
  end
end
