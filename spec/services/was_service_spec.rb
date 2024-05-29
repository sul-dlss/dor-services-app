# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WasService do
  describe '#crawl?' do
    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflows:) }
    let(:druid) { 'druid:bc123df4567' }

    context 'when the object is a crawl' do
      let(:workflows) { ['wasCrawlPreassemblyWF'] }

      it 'returns true' do
        expect(described_class.crawl?(druid:)).to be true
        expect(workflow_client).to have_received(:workflows).with(druid)
      end
    end

    context 'when the object is not a crawl' do
      let(:workflows) { ['preassemblyWF'] }

      it 'returns false' do
        expect(described_class.crawl?(druid:)).to be false
      end
    end
  end
end
