# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::BatchService do
  let(:druid1) { 'druid:bb033gt0615' }
  let(:druid2) { 'druid:bc033gt0616' }

  describe '#workflows' do
    subject(:workflows) { described_class.workflows(druids: [druid1, druid2]) }

    let!(:steps) do
      [
        create(:workflow_step, :with_ocr_context, druid: druid1, updated_at: '2025-07-22T21:35:36+00:00',
                                                  status: 'waiting')
      ]
    end

    before do
      create(:workflow_step, :with_ocr_context, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00', version: 2)
      create(:workflow_step, :with_ocr_context, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00',
                                                status: 'waiting')
      create(:workflow_step, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00', process: 'start',
                             workflow: 'wasCrawlPreassemblyWF')
    end

    it 'returns workflows' do
      expect(workflows).to be_a(Hash)
      expect(workflows.size).to eq 2
      expect(workflows[druid1].size).to eq 1
      workflow = workflows[druid1].first
      expect(workflow.workflow_name).to eq 'accessionWF'
      expect(workflow).to be_a(Workflow::WorkflowResponse)
      expect(workflow.steps).to eq steps
      expect(workflows[druid2].size).to eq 2
    end
  end
end
