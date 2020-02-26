# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Administrative tags' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:item) { Dor::Item.new(pid: druid) }
  let(:tags) do
    [
      'Process : Content Type : Map',
      'Project : Foo Maps : Batch 1',
      'Registered By : mjgiarlo',
      'Remediated By : 1.2.3'
    ]
  end

  before do
    allow(Dor).to receive(:find).and_return(item)
  end

  describe 'display' do
    context 'when item is not found' do
      before do
        allow(Dor).to receive(:find)
          .and_raise(ActiveFedora::ObjectNotFoundError, "Unable to find '#{druid}' in fedora. See logger for details.")
      end

      it 'returns a 404' do
        get "/v1/objects/#{druid}/administrative_tags",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response.status).to eq(404)
        expect(response.body).to eq('Unable to find \'druid:mx123qw2323\' in fedora. See logger for details.')
      end
    end

    context 'when item is found' do
      before do
        allow(AdministrativeTags).to receive(:for).and_return(tags)
      end

      it 'returns a 200' do
        get "/v1/objects/#{druid}/administrative_tags",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(AdministrativeTags).to have_received(:for).with(item: item).once
        expect(response.status).to eq(200)
        expect(response.body).to eq(tags.to_json)
      end
    end
  end

  describe 'creation' do
    before do
      allow(AdministrativeTags).to receive(:create)
    end

    context 'when happy path' do
      it 'adds administrative tags' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":#{tags.to_json}} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(AdministrativeTags).to have_received(:create)
          .with(item: item, tags: tags)
        expect(response.status).to eq(201)
      end
    end

    context 'without JSON content-type' do
      it 'returns an error' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":#{tags.to_json}} ),
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":"\"Content-Type\" request header must be set to \"application/json\"."}]}')
      end
    end

    context 'when administrative tags are missing' do
      it 'returns an error' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"foo":"bar"} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":' \
                                    '"#/paths/~1v1~1objects~1{object_id}~1administrative_tags/post/requestBody/content/application~1json/schema ' \
                                    'missing required parameters: administrative_tags"}]}')
      end
    end

    context 'when administrative tags are empty' do
      it 'returns an error' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":[]} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":' \
                                    '"#/paths/~1v1~1objects~1{object_id}~1administrative_tags/post/requestBody/content/application~1json/schema' \
                                    '/properties/administrative_tags [] contains fewer than min items"}]}')
      end
    end
  end
end
