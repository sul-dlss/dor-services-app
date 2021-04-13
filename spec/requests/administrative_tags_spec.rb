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
    before do
      allow(AdministrativeTags).to receive(:for).and_return(tags)
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/administrative_tags",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(AdministrativeTags).to have_received(:for).with(pid: druid).once
      expect(response.status).to eq(200)
      expect(response.body).to eq(tags.to_json)
    end
  end

  describe '#create' do
    before do
      allow(AdministrativeTags).to receive(:create)
    end

    context 'when happy path (without replacement)' do
      it 'adds administrative tags' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":#{tags.to_json}} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(AdministrativeTags).to have_received(:create)
          .with(pid: druid, tags: tags, replace: nil)
        expect(response.status).to eq(201)
      end
    end

    context 'when happy path (with replacement)' do
      it 'replaces administrative tags' do
        post "/v1/objects/#{druid}/administrative_tags",
             params: %( {"administrative_tags":#{tags.to_json},"replace":true} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(AdministrativeTags).to have_received(:create)
          .with(pid: druid, tags: tags, replace: true)
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
          .with(pid: druid, current: current_tag, new: new_tag)
        expect(response.status).to eq(204)
      end
    end

    context 'when tags have a dot in them' do
      let(:current_tag) { 'Remediated By : 4.21.4' }
      let(:new_tag) { 'Remediated By : 4.21.5' }

      it 'correctly routes and updates an administrative tag' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(AdministrativeTags).to have_received(:update)
          .with(pid: druid, current: current_tag, new: new_tag)
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

    context 'when the new tag already exists' do
      # NOTE: Yep, this is pretty gross. Faking ActiveModel::Errors here. Why is it gross?
      #       First, you can't raise ActiveRecord::RecordInvalid with a string. An instance must be supplied
      #       that responds to `#errors`, and what is returned by `#errors` must itself respond to `#full_messages`.
      #       A fun added complication is that the class of what is returned at the top level must respond
      #       to `#i18n_scope` (at the class level, not the instance level). We get that here by virtue of
      #       subclassing `AdministrativeTag` in the anonymous class. (FWIW, the return value of that method
      #       in this context? `:activerecord`.)
      let(:fake_invalid_record) do
        Class.new(AdministrativeTag) do
          def errors
            Class.new do
              def full_messages
                [
                  'Tag has already been assigned to the given druid (no duplicate tags for a druid)'
                ]
              end
            end.new
          end
        end.new
      end

      before do
        allow(AdministrativeTags).to receive(:update)
          .and_raise(ActiveRecord::RecordInvalid.new(fake_invalid_record))
      end

      it 'adds no new administrative tags' do
        put "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}",
            params: %( {"administrative_tag":"#{new_tag}"} ),
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(409)
        expect(response.body).to eq('Validation failed: Tag has already been assigned to the given druid (no duplicate tags for a druid)')
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
          .with(pid: druid, tag: tag)
        expect(response.status).to eq(204)
      end
    end

    context 'when a tag has a dot in it' do
      let(:tag) { 'Remediated By : 4.21.4' }

      it 'correctly routes and destroys an administrative tag' do
        delete "/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}",
               headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(AdministrativeTags).to have_received(:destroy)
          .with(pid: druid, tag: tag)
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
