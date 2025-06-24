# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show workflow' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow: workflow) }

  let(:druid) { 'druid:mw971zk1113' }

  let(:workflow) { instance_double(Dor::Workflow::Response::Workflow, xml: ng_xml) }
  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    <<~XML
      <workflow repository="dor" objectId="druid:mw971zk1113" id="accessionWF">
        <process laneId="default" lifecycle="submitted" elapsed="0.0" attempts="1" datetime="2013-02-18T15:08:10-0800" status="completed" name="start-accession"/>
      </workflow>
    XML
  end

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  context 'when successful' do
    it 'returns the workflow XML' do
      get "/v1/objects/#{druid}/workflows/accessionWF",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(Nokogiri::XML(response.parsed_body).to_s).to match(ng_xml.to_s)
      expect(workflow_client).to have_received(:workflow).with(pid: druid, workflow_name: 'accessionWF')
    end
  end

  context 'when the druid is not found' do
    before do
      allow(workflow_client).to receive(:workflow)
        .and_raise(Dor::MissingWorkflowException.new('HTTP status 404 Not Found'))
    end

    it 'returns a 404 error' do
      get "/v1/objects/#{druid}/workflows/accessionWF",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when some other HTTP error' do
    before do
      allow(workflow_client).to receive(:workflow)
        .and_raise(Dor::WorkflowException.new('HTTP status 400 Bad Request'))
    end

    it 'returns an HTTP error' do
      get "/v1/objects/#{druid}/workflows/accessionWF",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when some other error' do
    before do
      allow(workflow_client).to receive(:workflow)
        .and_raise(Dor::WorkflowException.new('Faraday connection error'))
    end

    it 'returns an 500 error' do
      get "/v1/objects/#{druid}/workflows/accessionWF",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:server_error)
    end
  end
end
