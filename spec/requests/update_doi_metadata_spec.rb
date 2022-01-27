# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update DOI metadata' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  let(:cocina_item) do
    Cocina::Models.build({
                           externalIdentifier: 'druid:bc123df4567',
                           'type' => Cocina::Models::Vocab.image,
                           version: 1,
                           label: 'testing',
                           access: {},
                           administrative: {
                             hasAdminPolicy: 'druid:xx123xx4567'
                           },
                           description: {
                             title: [{ value: 'Test obj' }],
                             purl: 'https://purl.stanford.edu/bc123df4567',
                             subject: [{ type: 'topic', value: 'word' }],
                             contributor: [
                               {
                                 name: [
                                   {
                                     structuredValue: [
                                       {
                                         value: 'Jane',
                                         type: 'forename'
                                       },
                                       {
                                         value: 'Stanford',
                                         type: 'surname'
                                       }
                                     ]
                                   }
                                 ],
                                 type: 'person'
                               }
                             ],
                             form: [
                               {
                                 structuredValue: [
                                   {
                                     value: 'Data',
                                     type: 'type'
                                   }
                                 ],
                                 source: {
                                   value: 'Stanford self-deposit resource types'
                                 },
                                 type: 'resource type'
                               },
                               {
                                 value: 'Dataset',
                                 type: 'resource type',
                                 uri: 'http://id.loc.gov/vocabulary/resourceTypes/dat',
                                 source: {
                                   uri: 'http://id.loc.gov/vocabulary/resourceTypes/'
                                 }
                               },
                               {
                                 value: 'Data sets',
                                 type: 'genre',
                                 uri: 'https://id.loc.gov/authorities/genreForms/gf2018026119',
                                 source: {
                                   code: 'lcgft'
                                 }
                               },
                               {
                                 value: 'dataset',
                                 type: 'genre',
                                 source: {
                                   code: 'local'
                                 }
                               },
                               {
                                 value: 'Dataset',
                                 type: 'resource type',
                                 source: {
                                   value: 'DataCite resource types'
                                 }
                               }
                             ]
                           },
                           structural: {
                             contains: []
                           },
                           identification: {
                             doi: '10.80343/bc123df4567'
                           }
                         })
  end

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(Cocina::Mapper).to receive(:build).and_return(cocina_item)
    allow(UpdateDoiMetadataJob).to receive(:perform_later)
  end

  context 'when enabled' do
    before do
      allow(Settings.enabled_features).to receive(:datacite_update).and_return(true)
    end

    context 'when the item meets the required preconditions' do
      it 'responds to the request with 202 ("accepted")' do
        post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:accepted)
        expect(UpdateDoiMetadataJob).to have_received(:perform_later)
      end
    end

    context 'when the item is missing the required preconditions' do
      let(:cocina_item) do
        Cocina::Models.build(
          'externalIdentifier' => 'druid:bc123df4567',
          'type' => Cocina::Models::Vocab.image,
          'version' => 1,
          'label' => 'testing',
          'access' => {},
          'administrative' => {
            'hasAdminPolicy' => 'druid:xx123xx4567'
          },
          'description' => {
            'title' => [{ 'value' => 'Test obj' }],
            'purl' => 'https://purl.stanford.edu/bc123df4567',
            'subject' => [{ 'type' => 'topic', 'value' => 'word' }]
          },
          'structural' => {
            'contains' => []
          },
          'identification' => {
            'doi' => '10.80343/bc123df4567'
          }
        )
      end

      it 'responds to the request with 409 ("conflict")' do
        post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:conflict)
        expect(UpdateDoiMetadataJob).not_to have_received(:perform_later)
      end
    end
  end

  context 'when disabled (default)' do
    it 'responds to the request with 204 ("no content")' do
      post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(UpdateDoiMetadataJob).not_to have_received(:perform_later)
    end
  end
end
