# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO access defaults to a member item' do
  before do
    allow(CocinaObjectStore).to receive(:find)
  end

  context 'when no exceptions are raised' do
    before do
      allow(ApplyAdminPolicyDefaults).to receive(:apply).and_return(nil)
    end

    it 'returns HTTP 204' do
      post '/v1/objects/druid:bc123df4567/apply_admin_policy_defaults',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response).to have_http_status(:no_content)
    end
  end

  context 'when an object type exception is raised' do
    before do
      allow(ApplyAdminPolicyDefaults).to receive(:apply).and_raise(
        ApplyAdminPolicyDefaults::UnsupportedObjectTypeError,
        'the error message does not really matter in this context'
      )
    end

    it 'returns HTTP 400 with an error message' do
      post '/v1/objects/druid:bc123df4567/apply_admin_policy_defaults',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).not_to be_successful
      expect(response).to have_http_status(:bad_request)
      # rubocop:disable Rails/ResponseParsedBody
      expect(JSON.parse(response.body)['errors'].first['detail']).to include(
        'the error message does not really matter in this context'
      )
      # rubocop:enable Rails/ResponseParsedBody
    end
  end

  context 'when a workflow state exception is raised' do
    before do
      allow(ApplyAdminPolicyDefaults).to receive(:apply).and_raise(
        ApplyAdminPolicyDefaults::UnsupportedWorkflowStateError,
        'the error message does not really matter in this context'
      )
    end

    it 'returns HTTP 422 with an error message' do
      post '/v1/objects/druid:bc123df4567/apply_admin_policy_defaults',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).not_to be_successful
      expect(response).to have_http_status(:unprocessable_entity)
      # rubocop:disable Rails/ResponseParsedBody
      expect(JSON.parse(response.body)['errors'].first['detail']).to include(
        'the error message does not really matter in this context'
      )
      # rubocop:enable Rails/ResponseParsedBody
    end
  end
end
