# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'background job result' do
  let(:background_job_result) { create(:background_job_result) }
  let(:body) { JSON.parse(response.body).with_indifferent_access }

  context 'when it does not exist' do
    it 'renders 404' do
      get '/v1/background_job_results/0',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
      expect(body[:errors].first[:title]).to eq('not found')
      expect(body[:errors].first[:detail]).to eq('Couldn\'t find BackgroundJobResult with \'id\'=0')
    end
  end

  context 'when it is pending' do
    before do
      get "/v1/background_job_results/#{background_job_result.id}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
    end

    it 'renders an HTTP 202 status code' do
      expect(response).to have_http_status(:accepted)
    end

    it 'states the job is pending' do
      expect(body[:status]).to eq('pending')
    end

    it 'has no output' do
      expect(body[:output]).to be_empty
    end
  end

  context 'when it is processing' do
    before do
      background_job_result.processing!
      get "/v1/background_job_results/#{background_job_result.id}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
    end

    it 'renders an HTTP 202 status code' do
      expect(response).to have_http_status(:accepted)
    end

    it 'states the job is processing' do
      expect(body[:status]).to eq('processing')
    end

    it 'has no output' do
      expect(body[:output]).to be_empty
    end
  end

  context 'when it is complete' do
    let(:background_job_result) { create(:background_job_result, code: code, output: output) }

    before do
      background_job_result.complete!
      get "/v1/background_job_results/#{background_job_result.id}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
    end

    context 'without errors' do
      let(:code) { 200 }
      let(:output) { { result: 'succeeded!' } }

      it 'renders an HTTP 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'states the job is complete' do
        expect(body[:status]).to eq('complete')
      end

      it 'has output from the job' do
        expect(body[:output][:result]).to eq('succeeded!')
      end
    end

    context 'with errors' do
      let(:code) { 200 }
      let(:output) { { errors: [{ detail: 'failed!' }] } }

      it 'renders an HTTP 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'states the job is complete' do
        expect(body[:status]).to eq('complete')
      end

      it 'has output from the job' do
        expect(body[:output][:errors].first[:detail]).to eq('failed!')
      end
    end
  end
end
