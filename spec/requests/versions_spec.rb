# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Operations regarding object versions' do
  let(:item) { Dor::Item.new(pid: 'druid:mx123qw2323') }

  before do
    allow(Dor).to receive(:find).and_return(item)
  end

  describe '/versions/current' do
    it 'returns the latest version for an object' do
      get '/v1/objects/druid:mx123qw2323/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq('1')
    end
  end

  describe '/versions/current/close' do
    context 'when closing a version succeedes' do
      before do
        allow(VersionService).to receive(:close)
      end

      it 'closes the current version when posted to' do
        post '/v1/objects/druid:mx123qw2323/versions/current/close',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(VersionService).to have_received(:close)
        expect(response.body).to match(/version 1 closed/)
      end

      it 'forwards optional params to the VersionService#close method' do
        post '/v1/objects/druid:mx123qw2323/versions/current/close',
             params: %( {"description": "some text", "significance": "major"} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to match(/version 1 closed/)
        expect(VersionService).to have_received(:close)
          .with(item,
                { description: 'some text', significance: 'major' },
                event_factory: EventFactory)
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
    # rubocop:disable RSpec/VerifiedDoubles
    let(:fake_events_ds) { double('events') }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:open_params) do
      {
        assume_accessioned: false,
        significance: 'minor',
        description: 'bar',
        opening_user_name: opening_user_name
      }
    end
    let(:opening_user_name) { 'foo' }

    before do
      allow(item).to receive(:current_version).and_return('2')
    end

    context 'when opening a version succeeds' do
      before do
        # Do not test version service side effects in dor-services-app; that is dor-services' responsibility
        allow(VersionService).to receive(:open)
      end

      it 'opens a new object version when posted to' do
        post '/v1/objects/druid:mx123qw2323/versions',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.body).to eq('2')
        expect(response).to be_successful
      end

      it 'forwards optional params to the VersionService#open method' do
        post '/v1/objects/druid:mx123qw2323/versions',
             params: open_params.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(VersionService).to have_received(:open).with(item, open_params, event_factory: EventFactory)
        expect(response.body).to eq('2')
        expect(response).to be_successful
      end
    end

    context 'when opening a version fails' do
      before do
        # Do not test version service side effects in dor-services-app; that is dor-services' responsibility
        allow(VersionService).to receive(:open).and_raise(Dor::Exception, 'Object net yet accessioned')
      end

      it 'returns an error' do
        post '/v1/objects/druid:mx123qw2323/versions',
             headers: { 'Authorization' => "Bearer #{jwt}" }
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
             headers: { 'Authorization' => "Bearer #{jwt}" }
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

      it 'returns true' do
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
