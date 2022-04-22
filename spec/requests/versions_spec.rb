# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Operations regarding object versions' do
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: 'druid:mx123qw2323',
                            type: Cocina::Models::ObjectType.book,
                            label: 'test object',
                            version: version,
                            access: {},
                            description: {
                              title: [{ value: 'test object' }],
                              purl: 'https://purl.stanford.edu/mx123qw2323'
                            },
                            administrative: {
                              hasAdminPolicy: 'druid:dd999df4567'
                            },
                            identification: {
                              sourceId: 'googlebooks:999999'
                            },
                            structural: {})
  end

  let(:date) { Time.zone.now }
  let(:lock) { 'abc123' }
  let(:cocina_object_with_metadata) do
    Cocina::Models.with_metadata(cocina_object, lock, created: date, modified: date)
  end
  let(:version) { 1 }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object_with_metadata)
  end

  describe '/versions/current' do
    it 'returns the latest version for an object' do
      get '/v1/objects/druid:mx123qw2323/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq('1')
    end
  end

  describe '/versions/current/close' do
    context 'when closing a version succeeds' do
      before do
        allow(VersionService).to receive(:close)
      end

      let(:closing_user_name) { 'some_sunetid1' }
      let(:close_params) do
        {
          significance: 'minor',
          description: 'bar',
          user_name: closing_user_name,
          event_factory: EventFactory
        }
      end

      it 'closes the current version when posted to' do
        post '/v1/objects/druid:mx123qw2323/versions/current/close',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(VersionService).to have_received(:close)
        expect(response.body).to match(/version 1 closed/)
      end

      it 'forwards params to the VersionService#close method' do
        post '/v1/objects/druid:mx123qw2323/versions/current/close',
             params: close_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to match(/version 1 closed/)
        expect(VersionService).to have_received(:close)
          .with(cocina_object_with_metadata,
                close_params)
      end
    end

    context 'when closing a version fails' do
      before do
        allow(VersionService).to receive(:close)
          .and_raise(Dor::Exception, 'Trying to close version on an object not opened for versioning')
      end

      it 'returns an error' do
        post '/v1/objects/druid:mx123qw2323/versions/current/close',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq(
          '{"errors":[{"status":"422","title":"Unable to close version",' \
          '"detail":"Trying to close version on an object not opened for versioning"}]}'
        )
        expect(response.status).to eq 422
      end
    end
  end

  describe '/versions' do
    let(:open_params) do
      {
        assume_accessioned: false,
        significance: 'minor',
        description: 'bar',
        opening_user_name: opening_user_name,
        event_factory: EventFactory
      }
    end
    let(:opening_user_name) { 'sunetid666' }

    let(:version) { 2 }

    context 'when opening a version succeeds' do
      before do
        # Do not test version service side effects here; see version_service_spec
        allow(VersionService).to receive(:open).and_return(cocina_object_with_metadata)
      end

      it 'opens a new object version when posted to' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: open_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response).to be_successful
        expect(response.body).to equal_cocina_model(cocina_object)
        expect(response.headers['Last-Modified']).to end_with 'GMT'
        expect(response.headers['X-Created-At']).to end_with 'GMT'
        expect(response.headers['ETag']).to match(%r{W/".+"})
      end

      it 'forwards params to the VersionService#open method' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: open_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(VersionService).to have_received(:open)
          .with(cocina_object_with_metadata,
                open_params)
        expect(response.body).to equal_cocina_model(cocina_object)
        expect(response).to be_successful
      end
    end

    context 'when required params are missing' do
      let(:incomplete_params) do
        {
          assume_accessioned: false,
          opening_user_name: opening_user_name
        }
      end

      it 'returns a bad request error' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: incomplete_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        # rubocop:disable Layout/LineLength
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":"#/paths/~1v1~1objects~1{object_id}~1versions/post missing required parameters: description, significance"}]}')
        # rubocop:enable Layout/LineLength
        expect(response.status).to eq 400
      end
    end

    context 'when opening a version fails' do
      before do
        # Do not test version service side effects here; see version_service_spec
        allow(VersionService).to receive(:open).and_raise(Dor::Exception, 'Object net yet accessioned')
      end

      it 'returns an error' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: open_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq('{"errors":[{"status":"422","title":"Unable to open version","detail":"Object net yet accessioned"}]}')
        expect(response.status).to eq 422
      end
    end

    context 'when preservation client call fails' do
      before do
        allow(VersionService).to receive(:open).and_raise(Preservation::Client::UnexpectedResponseError, 'Oops, a 500')
      end

      it 'returns an error' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: open_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq('{"errors":[{"status":"500","title":"Unable to open version due to preservation client error","detail":"Oops, a 500"}]}')
        expect(response.status).to eq 500
      end
    end
  end

  describe '/versions/openable' do
    context 'when a new version can be opened' do
      before do
        allow(VersionService).to receive(:can_open?).and_return(true)
      end

      it 'returns true' do
        get '/v1/objects/druid:mx123qw2323/versions/openable',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('true')
        expect(response).to be_successful
      end
    end

    context 'when a new version cannot be opened' do
      before do
        allow(VersionService).to receive(:can_open?).and_return(false)
      end

      it 'returns false' do
        get '/v1/objects/druid:mx123qw2323/versions/openable',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('false')
        expect(response).to be_successful
      end
    end

    context 'when preservation client call fails' do
      before do
        allow(VersionService).to receive(:can_open?).and_raise(Preservation::Client::UnexpectedResponseError, 'Oops, a 500')
      end

      it 'returns an error' do
        get '/v1/objects/druid:mx123qw2323/versions/openable',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('{"errors":[{"status":"500","title":"Unable to check if openable due to preservation client error","detail":"Oops, a 500"}]}')
        expect(response.status).to eq 500
      end
    end
  end
end
