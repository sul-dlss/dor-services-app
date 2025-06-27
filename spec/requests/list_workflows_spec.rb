# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List workflows' do
  let(:druid) { 'druid:gv054hp4128' }

  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    <<~XML
      <workflows objectId="druid:mw971zk1113">
        <workflow repository="dor" objectId="druid:mw971zk1113" id="assemblyWF">
        </workflow>
        <workflow repository="dor" objectId="druid:mw971zk1113" id="sdrPreservationWF">
        </workflow>
      </workflows>
    XML
  end

  before do
    allow(WorkflowService).to receive(:workflows_xml).and_return(ng_xml)
  end

  context 'when successful' do
    it 'returns the workflows XML' do
      get "/v1/objects/#{druid}/workflows",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(Nokogiri::XML(response.parsed_body).to_s).to match(ng_xml.to_s)
      expect(WorkflowService).to have_received(:workflows_xml).with(druid:)
    end
  end

  context 'when the druid is not found' do
    before do
      allow(WorkflowService).to receive(:workflows_xml)
        .and_raise(WorkflowService::NotFoundException)
    end

    it 'returns a 404 error' do
      get "/v1/objects/#{druid}/workflows",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when some other HTTP error' do
    before do
      allow(WorkflowService).to receive(:workflows_xml)
        .and_raise(WorkflowService::Exception.new('HTTP status 400 Bad Request', status: 400))
    end

    it 'returns an HTTP error' do
      get "/v1/objects/#{druid}/workflows",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when some other error' do
    before do
      allow(WorkflowService).to receive(:workflows_xml)
        .and_raise(WorkflowService::Exception.new('Faraday connection error'))
    end

    it 'returns an 500 error' do
      get "/v1/objects/#{druid}/workflows",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:server_error)
    end
  end

  # This can be removed once the workflow client has been removed.
  describe 'testing workflow client error handling' do
    let(:workflows) { instance_double(Dor::Workflow::Response::Workflows, xml: ng_xml) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, all_workflows: workflows) }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(WorkflowService).to receive(:workflows_xml).and_call_original
    end

    context 'when some other HTTP error' do
      before do
        allow(workflow_client).to receive(:all_workflows)
          .and_raise(Dor::WorkflowException.new('HTTP status 400 Bad Request'))
      end

      it 'returns an HTTP error' do
        get "/v1/objects/#{druid}/workflows",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when some other error' do
      before do
        allow(workflow_client).to receive(:all_workflows)
          .and_raise(Dor::WorkflowException.new('Faraday connection error'))
      end

      it 'returns an 500 error' do
        get "/v1/objects/#{druid}/workflows",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:server_error)
      end
    end
  end
end
