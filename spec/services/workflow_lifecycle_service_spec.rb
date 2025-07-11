# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowLifecycleService do
  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
        <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone>
        </lifecycle>
      </xml>
    XML
  end

  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  let(:druid) { 'druid:gv054hp4128' }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(workflow_client).to receive(:query_lifecycle).and_return(ng_xml)
  end

  describe '#lifecycle_xml' do
    it 'returns the lifecycle XML' do
      expect(described_class.lifecycle_xml(druid:, version: 3, active_only: true)).to eq ng_xml

      expect(workflow_client).to have_received(:query_lifecycle).with(druid, version: 3, active_only: true)
    end
  end

  describe '#milestone?' do
    context 'when the milestone exists' do
      it 'returns true' do
        expect(described_class.milestone?(druid:, version: 3, active_only: true, milestone_name: 'published'))
          .to be true

        expect(workflow_client).to have_received(:query_lifecycle).with(druid, version: 3, active_only: true)
      end
    end

    context 'when the milestone does not exist' do
      it 'returns true' do
        expect(described_class.milestone?(druid:, milestone_name: 'accessioned'))
          .to be false

        expect(workflow_client).to have_received(:query_lifecycle).with(druid, version: nil, active_only: false)
      end
    end
  end

  describe '#milestones' do
    subject(:milestones) { described_class.milestones(druid: druid) }

    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone>
        </lifecycle>
      XML
    end

    it 'includes the version in with the milestones' do
      expect(milestones.first[:milestone]).to eq('published')
      expect(milestones.first[:version]).to eq('2')
    end
  end
end
