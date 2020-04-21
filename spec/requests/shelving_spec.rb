# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Shelve object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  let(:job) { class_double(ShelveJob, perform_later: nil) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ShelveJob).to receive(:set).and_return(job)
  end

  context 'with a collection' do
    let(:object) { Dor::Collection.new(pid: druid) }

    it 'returns a 422 error' do
      post "/v1/objects/#{druid}/shelve", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors'].first['detail']).to eq("A Dor::Item is required but you provided 'Dor::Collection'")
      expect(job).not_to have_received(:perform_later)
    end
  end

  context 'when the request is successful' do
    it 'calls ShelvingService and returns201' do
      post "/v1/objects/#{druid}/shelve?lane-id=low", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:created)
      expect(ShelveJob).to have_received(:set).with(queue: :low)
      expect(job).to have_received(:perform_later)
        .with(druid: druid, background_job_result: BackgroundJobResult)
    end
  end
end
