# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publish object' do
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(PublishJob).to receive(:perform_later)
  end

  context 'with a workflow provided' do
    it 'calls PublishMetadataService and returns 201' do
      post '/v1/objects/druid:1234/publish?workflow=releaseWF', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(PublishJob).to have_received(:perform_later)
        .with(druid: 'druid:1234', background_job_result: BackgroundJobResult, workflow: 'releaseWF')
      expect(response.status).to eq(201)
    end
  end

  context 'with an invalid workflow provided' do
    it 'calls PublishMetadataService and returns 201' do
      expect do
        post '/v1/objects/druid:1234/publish?workflow=badWF', headers: { 'Authorization' => "Bearer #{jwt}" }
      end.to raise_error('invalid workflow badWF')
    end
  end

  context 'without a workflow provided' do
    # This happens when Argo invokes the API
    it 'calls PublishMetadataService and returns 201' do
      post '/v1/objects/druid:1234/publish', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(PublishJob).to have_received(:perform_later)
        .with(druid: 'druid:1234', background_job_result: BackgroundJobResult, workflow: nil)
      expect(response.status).to eq(201)
    end
  end
end
