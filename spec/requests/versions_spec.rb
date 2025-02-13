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

  describe 'GET /versions/current' do
    it 'returns the latest version for an object' do
      get '/v1/objects/druid:mx123qw2323/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq('1')
    end
  end

  describe 'POST /versions' do
    it 'returns the version status for the provided druids' do
      get '/v1/objects/druid:mx123qw2323/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq('1')
    end
  end

  describe 'DELETE /versions/current' do
    context 'when discarding a version succeeds' do
      before do
        allow(VersionService).to receive(:discard)
        allow(CleanupVersionJob).to receive(:perform_later)
      end

      it 'returns no content' do
        delete '/v1/objects/druid:mx123qw2323/versions/current',
               headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status :no_content
        expect(VersionService).to have_received(:discard).with(druid: druid, version: version)
        expect(CleanupVersionJob).to have_received(:perform_later).with(druid: druid, version: version)
      end
    end

    context 'when discarding a version fails' do
      before do
        allow(VersionService).to receive(:discard).and_raise(VersionService::VersioningError, 'Trying to discard a version that is not discardable')
      end

      it 'returns conflict' do
        delete '/v1/objects/druid:mx123qw2323/versions/current',
               headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status :conflict
      end
    end
  end

  describe 'POST /versions/current/close' do
    let(:close_params) do
      {
        description: 'some text',
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
        expect(response).to have_http_status :unprocessable_content
        expect(response.body).to eq(
          '{"errors":[{"status":"422","title":"Unable to close version",' \
          '"detail":"Trying to close version on an object not opened for versioning"}]}'
        )
      end
    end
  end

  describe 'POST /v1/objects/:druid/versions' do
    let(:open_params) do
      {
        assume_accessioned: false,
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
        expect(response).to have_http_status :unprocessable_content
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

  describe 'GET /versions/status' do
    let(:version_service) { instance_double(VersionService, can_open?: false, can_close?: true, open?: true, can_discard?: true) }
    let(:workflow_state_service) { instance_double(WorkflowStateService, assembling?: true, accessioning?: false) }

    before do
      allow(VersionService).to receive(:new).and_return(version_service)
      allow(WorkflowStateService).to receive(:new).and_return(workflow_state_service)
      create(:repository_object_version, :with_repository_object, external_identifier: druid, version: 1)
    end

    it 'returns the version status for an object' do
      get '/v1/objects/druid:mx123qw2323/versions/status',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.parsed_body.with_indifferent_access).to match({
                                                                      versionId: 1,
                                                                      open: true,
                                                                      openable: false,
                                                                      assembling: true,
                                                                      accessioning: false,
                                                                      closeable: true,
                                                                      discardable: true,
                                                                      versionDescription: 'Best version ever'
                                                                    })
    end
  end

  describe 'POST /versions/status' do
    let(:druids) { ['druid:mx123qw2323', 'druid:fp165nz4391', 'druid:bm077td6448'] }
    let(:version_service1) { instance_double(VersionService, can_open?: false, can_close?: true, open?: true, can_discard?: true) }
    let(:version_service2) { instance_double(VersionService, can_open?: true, can_close?: false, open?: false, can_discard?: false) }
    let(:workflow_state_service1) { instance_double(WorkflowStateService, assembling?: true, accessioning?: false) }
    let(:workflow_state_service2) { instance_double(WorkflowStateService, assembling?: false, accessioning?: true) }

    before do
      create(:repository_object_version, :with_repository_object, external_identifier: druids[0], version: 1)
      create(:repository_object_version, :with_repository_object, external_identifier: druids[1], version: 2)
      allow(CocinaObjectStore).to receive(:version).with(druids[0]).and_return(1)
      allow(CocinaObjectStore).to receive(:version).with(druids[1]).and_return(2)
      allow(CocinaObjectStore).to receive(:version).with(druids[2]).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)

      allow(VersionService).to receive(:new).with(druid: druids[0], version: 1).and_return(version_service1)
      allow(VersionService).to receive(:new).with(druid: druids[1], version: 2).and_return(version_service2)
      allow(WorkflowStateService).to receive(:new).with(druid: druids[0], version: 1).and_return(workflow_state_service1)
      allow(WorkflowStateService).to receive(:new).with(druid: druids[1], version: 2).and_return(workflow_state_service2)
    end

    it 'returns the version status for the provided druids' do
      post '/v1/objects/versions/status',
           params: { externalIdentifiers: druids }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.parsed_body.with_indifferent_access).to match('druid:mx123qw2323' => {
                                                                      versionId: 1,
                                                                      open: true,
                                                                      openable: false,
                                                                      assembling: true,
                                                                      accessioning: false,
                                                                      closeable: true,
                                                                      discardable: true,
                                                                      versionDescription: 'Best version ever'
                                                                    },
                                                                    'druid:fp165nz4391' => {
                                                                      versionId: 2,
                                                                      open: false,
                                                                      openable: true,
                                                                      assembling: false,
                                                                      accessioning: true,
                                                                      closeable: false,
                                                                      discardable: false,
                                                                      versionDescription: 'Best version ever'
                                                                    })
    end
  end
end
