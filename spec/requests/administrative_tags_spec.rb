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

  describe '#show' do
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

  describe '#create' do
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

    context 'when item is not found' do
      before do
        allow(Dor).to receive(:find)
          .and_raise(ActiveFedora::ObjectNotFoundError, "Unable to find '#{druid}' in fedora. See logger for details.")
      end

      it 'returns a 404' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":#{tags.to_json}} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(404)
        expect(response.body).to eq('Unable to find \'druid:mx123qw2323\' in fedora. See logger for details.')
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

  describe '#update' do
    let(:current_tag) { 'Replace : Me' }
    let(:new_tag) { 'Much : Better : Tag' }

    before do
      allow(AdministrativeTags).to receive(:update)
    end

    context 'when happy path' do
      it 'updates an administrative tag' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(AdministrativeTags).to have_received(:update)
          .with(item: item, current: current_tag, new: new_tag)
        expect(response.status).to eq(204)
      end
    end

    context 'when item is not found' do
      before do
        allow(Dor).to receive(:find)
          .and_raise(ActiveFedora::ObjectNotFoundError, "Unable to find '#{druid}' in fedora. See logger for details.")
      end

      it 'returns a 404' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(404)
        expect(response.body).to eq('Unable to find \'druid:mx123qw2323\' in fedora. See logger for details.')
      end
    end

    context 'when tag is not found' do
      before do
        allow(AdministrativeTags).to receive(:update)
          .and_raise(ActiveRecord::RecordNotFound, "Couldn't find AdministrativeTag")
      end

      it 'returns a 404' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(404)
        expect(response.body).to eq('Couldn\'t find AdministrativeTag')
      end
    end

    context 'without JSON content-type' do
      it 'returns an error' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":"\"Content-Type\" request header must be set to \"application/json\"."}]}')
      end
    end

    context 'when administrative tag param is missing' do
      it 'returns an error' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"foo":"bar"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":' \
                                    '"#/paths/~1v1~1objects~1{object_id}~1administrative_tags~1{id}/put/requestBody/content/application~1json/schema ' \
                                    'missing required parameters: administrative_tag"}]}')
      end
    end

    context 'when administrative tag params is empty' do
      it 'returns an error' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":""} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":' \
                                    '"#/components/schemas/AdministrativeTag pattern ^.+( : .+)+$ does not match value: , example: Foo : Bar : Baz"}]}')
      end
    end
  end

  describe '#destroy' do
    let(:tag) { 'Delete : Me' }

    before do
      allow(AdministrativeTags).to receive(:destroy)
    end

    context 'when happy path' do
      it 'destroys an administrative tag' do
        delete "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}",
               headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(AdministrativeTags).to have_received(:destroy)
          .with(item: item, tag: tag)
        expect(response.status).to eq(204)
      end
    end

    context 'when item is not found' do
      before do
        allow(Dor).to receive(:find)
          .and_raise(ActiveFedora::ObjectNotFoundError, "Unable to find '#{druid}' in fedora. See logger for details.")
      end

      it 'returns a 404' do
        delete "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}",
               headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(404)
        expect(response.body).to eq('Unable to find \'druid:mx123qw2323\' in fedora. See logger for details.')
      end
    end

    context 'when tag is not found' do
      before do
        allow(AdministrativeTags).to receive(:destroy)
          .and_raise(ActiveRecord::RecordNotFound, "Couldn't find AdministrativeTag")
      end

      it 'returns an error' do
        delete "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}",
               headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(404)
        expect(response.body).to eq('Couldn\'t find AdministrativeTag')
      end
    end
  end
end
