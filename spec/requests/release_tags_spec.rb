# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release tags' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  describe 'display' do
    context 'when item is not found' do
      before do
        allow(ReleaseTags).to receive(:for)
        allow(Dor).to receive(:find)
          .and_raise(ActiveFedora::ObjectNotFoundError, "Unable to find '#{druid}' in fedora. See logger for details.")
      end

      it 'returns a 404' do
        get "/v1/objects/#{druid}/release_tags",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(ReleaseTags).not_to have_received(:for)
        expect(response.status).to eq(404)
        expect(response.body).to eq('Unable to find \'druid:mx123qw2323\' in fedora. See logger for details.')
      end
    end

    context 'when item is found' do
      before do
        allow(Dor).to receive(:find).and_return(object)
        allow(ReleaseTags).to receive(:for).and_return(
          'SearchWorks' => { 'release' => true },
          'elsewhere' => { 'release' => false }
        )
      end

      it 'returns a 200' do
        get "/v1/objects/#{druid}/release_tags",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(ReleaseTags).to have_received(:for).with(item: object).once
        expect(response.status).to eq(200)
        expect(response.body).to eq('{"SearchWorks":{"release":true},"elsewhere":{"release":false}}')
      end
    end
  end

  describe 'creation' do
    before do
      allow(Dor).to receive(:find).and_return(object)
      allow(ReleaseTags).to receive(:create)
      allow(object).to receive(:save)
    end

    context 'when release is false' do
      it 'adds a release tag' do
        post "/v1/objects/#{druid}/release_tags",
             params: %( {"to":"searchworks","who":"carrickr","what":"self","release":false} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(ReleaseTags).to have_received(:create)
          .with(Dor::Item, release: false, to: 'searchworks', who: 'carrickr', what: 'self')
        expect(object).to have_received(:save)
        expect(response.status).to eq(201)
      end
    end

    context 'when release is true' do
      it 'adds a release tag' do
        post "/v1/objects/#{druid}/release_tags",
             params: %( {"to":"searchworks","who":"carrickr","what":"self","release":true} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(ReleaseTags).to have_received(:create)
          .with(Dor::Item, release: true, to: 'searchworks', who: 'carrickr', what: 'self')
        expect(object).to have_received(:save)
        expect(response.status).to eq(201)
      end
    end

    context 'without JSON content-type' do
      it 'returns an error' do
        post "/v1/objects/#{druid}/release_tags",
             params: %( {"to":"searchworks","who":"carrickr","what":"self","release":"seven"} ),
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":"\"Content-Type\" request header must be set to \"application/json\"."}]}')
      end
    end

    context 'with an invalid release attribute' do
      it 'returns an error' do
        post "/v1/objects/#{druid}/release_tags",
             params: %( {"to":"searchworks","who":"carrickr","what":"self","release":"seven"} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq('{"errors":[{"status":"bad_request","detail":"#/components/schemas/ReleaseTag/properties/release expected boolean, but received String: \\"seven\\""}]}')
      end
    end

    context 'with a missing release attribute' do
      it 'returns an error' do
        post '/v1/objects/druid:1234/release_tags',
             params: %( {"to":"searchworks","who":"carrickr","what":"self"} ),
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(400)
        expect(response.body).to eq(
          '{"errors":[{"status":"bad_request",'\
          '"detail":"#/components/schemas/Druid pattern '\
          '^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$ does not match value: \\"druid:1234\\", example: druid:bc123df4567"}]}'
        )
      end
    end
  end
end
