# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Operations regarding object versions' do
  let(:cocina_object) { build(:dro, id: druid) }

  let(:date) { Time.zone.now }

  let(:lock) { 'abc123' }

  let(:druid) { 'druid:mx123qw2323' }

  let(:cocina_object_with_metadata) do
    Cocina::Models.with_metadata(cocina_object, lock, created: date, modified: date)
  end

  let(:version) { 1 }

  before do
    allow(CocinaObjectStore).to receive_messages(find: cocina_object_with_metadata, version:)
  end

  describe '/versions/current' do
    it 'returns the latest version for an object' do
      get '/v1/objects/druid:mx123qw2323/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq('1')
    end
  end

  describe '/versions/current/close' do
    let(:close_params) do
      {
        description: 'some text',
        significance: 'major',
        user_name: 'eshackleton',
        start_accession: false
      }
    end

    context 'when closing a version succeeds' do
      before do
        allow(VersionService).to receive(:close)
      end

      it 'closes the current version when posted to' do
        post "/v1/objects/druid:mx123qw2323/versions/current/close?#{close_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status :ok
        expect(response.body).to match(/version 1 closed/)
        expect(VersionService).to have_received(:close)
          .with(druid:, version:,
                **close_params)
      end
    end

    context 'when closing a version fails' do
      before do
        allow(VersionService).to receive(:close)
          .and_raise(VersionService::VersioningError, 'Trying to close version on an object not opened for versioning')
      end

      it 'returns an error' do
        post "/v1/objects/druid:mx123qw2323/versions/current/close?#{close_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status :unprocessable_entity
        expect(response.body).to eq(
          '{"errors":[{"status":"422","title":"Unable to close version",' \
          '"detail":"Trying to close version on an object not opened for versioning"}]}'
        )
      end
    end
  end

  describe '/versions' do
    let(:open_params) do
      {
        assume_accessioned: false,
        significance: 'minor',
        description: 'bar',
        opening_user_name: 'eshackleton'
      }
    end

    let(:version) { 2 }

    context 'when opening a version succeeds' do
      before do
        # Do not test version service side effects in dor-services-app; that is dor-services' responsibility
        allow(VersionService).to receive(:open).and_return(cocina_object_with_metadata)
      end

      it 'opens a new object version when posted to' do
        post "/v1/objects/druid:mx123qw2323/versions?#{open_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to be_successful
        expect(response.body).to equal_cocina_model(cocina_object)
        expect(response.headers['Last-Modified']).to end_with 'GMT'
        expect(response.headers['X-Created-At']).to end_with 'GMT'
        expect(response.headers['ETag']).to match(%r{W/".+"})
        expect(VersionService).to have_received(:open).with(cocina_object: cocina_object_with_metadata, **open_params)
      end
    end

    context 'when required params are missing' do
      let(:incomplete_params) do
        {
          assume_accessioned: false,
          opening_user_name: 'eshackleton'
        }
      end

      it 'returns a bad request error' do
        post "/v1/objects/druid:mx123qw2323/versions?#{incomplete_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to match('missing required parameters: description')
        expect(response).to have_http_status :bad_request
      end
    end

    context 'when opening a version fails' do
      before do
        # Do not test version service side effects in dor-services-app; that is dor-services' responsibility
        allow(VersionService).to receive(:open).and_raise(VersionService::VersioningError, 'Object net yet accessioned')
      end

      it 'returns an error' do
        post "/v1/objects/druid:mx123qw2323/versions?#{open_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('{"errors":[{"status":"422","title":"Unable to open version","detail":"Object net yet accessioned"}]}')
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context 'when preservation client call fails' do
      before do
        allow(VersionService).to receive(:open).and_raise(Preservation::Client::UnexpectedResponseError, 'Oops, a 500')
      end

      it 'returns an error' do
        post "/v1/objects/druid:mx123qw2323/versions?#{open_params.to_query}",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('{"errors":[{"status":"500","title":"Unable to open version due to preservation client error","detail":"Oops, a 500"}]}')
        expect(response).to have_http_status :internal_server_error
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
        expect(response).to have_http_status :internal_server_error
      end
    end
  end
end
