# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowProcessService do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, update_status: true, update_error_status: true) }
  let(:druid) { 'druid:bb033gt0615' }
  let(:workflow_name) { 'accessionWF' }
  let(:process) { 'publish' }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.update' do
    context 'when the process exists' do
      it 'updates the process status successfully' do
        described_class.update(druid:, workflow_name:, process:, status: 'completed',
                               current_status: 'in_progress', elapsed: 5, lifecycle: 'published',
                               note: 'Process completed successfully')

        expect(workflow_client).to have_received(:update_status).with(
          druid:, workflow: workflow_name, process:, status: 'completed', elapsed: 5,
          lifecycle: 'published', note: 'Process completed successfully',
          current_status: 'in_progress'
        )
      end
    end

    context 'when the process does not exist' do
      before do
        allow(workflow_client).to receive(:update_status).and_raise(Dor::MissingWorkflowException)
      end

      it 'raises a NotFoundException' do
        expect do
          described_class.update(druid:, workflow_name:, process:, status: 'completed')
        end.to raise_error(WorkflowService::NotFoundException,
                           'Process publish not found in accessionWF for druid:bb033gt0615')
      end
    end

    context 'when there is a conflict' do
      before do
        allow(workflow_client).to receive(:update_status).and_raise(Dor::WorkflowException, 'HTTP status 409')
      end

      it 'raises a ConflictException' do
        expect do
          described_class.update(druid:, workflow_name:, process:, status: 'completed')
        end.to raise_error(WorkflowService::ConflictException)
      end
    end
  end

  describe '.update_error' do
    context 'when the process exists' do
      it 'updates the process status to error successfully' do
        described_class.update_error(druid:, workflow_name:, process:, error_msg: 'An error occurred',
                                     error_text: 'Detailed error information')

        expect(workflow_client).to have_received(:update_error_status).with(
          druid:, workflow: workflow_name, process:, error_msg: 'An error occurred',
          error_text: 'Detailed error information'
        )
      end
    end

    context 'when the process does not exist' do
      before do
        allow(workflow_client).to receive(:update_error_status).and_raise(Dor::MissingWorkflowException)
      end

      it 'raises a NotFoundException' do
        expect do
          described_class.update_error(druid:, workflow_name:, process:, error_msg: 'An error occurred')
        end.to raise_error(WorkflowService::NotFoundException,
                           'Process publish not found in accessionWF for druid:bb033gt0615')
      end
    end
  end
end
