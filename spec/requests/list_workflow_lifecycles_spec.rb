# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List workflow lifecycles' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, query_lifecycle: ng_xml) }

  let(:druid) { 'druid:gv054hp4128' }

  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    '<?xml version="1.0" encoding="UTF-8"?><lifecycle objectId="druid:gv054hp4128"><milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone></lifecycle>' # rubocop:disable Layout/LineLength
  end

  let(:templates) { ['assemblyWF', 'registrationWF'] }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  context 'when no params are provided' do
    it 'returns the lifecycle XML' do
      get "/v1/objects/#{druid}/lifecycles",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.parsed_body).to match(ng_xml)
      expect(workflow_client).to have_received(:query_lifecycle).with(druid: druid, version: nil, active_only: false)
    end
  end

  context 'when params are provided' do
    it 'returns the lifecycle XML' do
      get "/v1/objects/#{druid}/lifecycles",
          params: { version: '2', active_only: 'true' },
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.parsed_body).to match(ng_xml)
      expect(workflow_client).to have_received(:query_lifecycle).with(druid: druid, version: 2, active_only: true)
    end
  end
end
