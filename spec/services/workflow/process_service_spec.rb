# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::ProcessService do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, update_status: true, update_error_status: true) }
  let(:druid) { 'druid:bb033gt0615' }
  let(:workflow_name) { 'accessionWF' }
  let(:process) { 'publish' }

  describe '.update' do
    before do
      allow(Workflow::NextStepService).to receive(:enqueue_next_steps)
    end

    context 'when success after an error' do
      let(:step) do
        create(:workflow_step,
               status: 'error',
               error_msg: 'Bang!',
               error_txt: 'This is error',
               lifecycle: 'submitted')
      end

      it 'clears the old error message, but preserves the lifecycle' do
        expect do
          described_class.update(druid: step.druid, workflow_name: step.workflow, process: step.process,
                                 status: 'completed', elapsed: 5, lifecycle: 'submitted')
        end
          .to change { step.reload.status }.from('error').to('completed')
          .and change(step, :error_msg).to(nil)
          .and change(step, :error_txt).to(nil)
          .and(not_change { step.lifecycle })

        expect(Workflow::NextStepService).to have_received(:enqueue_next_steps).with(step:)
      end
    end

    context 'when a non-default lane_id' do
      let(:step) do
        create(:workflow_step, lane_id: 'low')
      end

      it 'does not change the lane_id' do
        expect do
          described_class.update(druid: step.druid, workflow_name: step.workflow, process: step.process,
                                 status: 'completed')
        end.to not_change { step.reload.lane_id }.from('low')
      end
    end

    context 'when no matching step exists (e.g. pres cat looks for 404 response to create missing workflow)' do
      let(:druid) { 'druid:zz696qh8598' }

      it 'raises a NotFoundException' do
        expect do
          described_class.update(druid: druid, workflow_name: 'hydrusAssemblyWF', process: 'submit',
                                 status: 'completed')
        end.to raise_error(Workflow::Service::NotFoundException)
      end
    end

    context 'when current status does not match' do
      let(:step) { create(:workflow_step) }

      it 'raises ConflictException' do
        expect do
          described_class.update(druid: step.druid, workflow_name: step.workflow, process: step.process,
                                 status: 'completed', current_status: 'not-waiting')
        end
          .to raise_error(Workflow::Service::ConflictException)
      end
    end

    context 'when current status matches' do
      let(:step) { create(:workflow_step) }

      it 'does not raise' do
        expect do
          described_class.update(druid: step.druid, workflow_name: step.workflow, process: step.process,
                                 status: 'completed', current_status: 'waiting')
        end.not_to raise_error
      end
    end

    context 'when there are multiple versions' do
      let(:version1_step) { create(:workflow_step, status: 'error', version: 1) }
      let(:version2_step) { create(:workflow_step, status: 'error', version: 2, druid: version1_step.druid) }

      it 'updates the newest version' do
        expect do
          described_class.update(druid: version2_step.druid, workflow_name: version2_step.workflow,
                                 process: version2_step.process, status: 'completed')
        end.to change { version2_step.reload.status }.from('error').to('completed')
                                                     .and not_change { version1_step.reload.status }.from('error')

        expect(Workflow::NextStepService).to have_received(:enqueue_next_steps).with(step: version2_step)
      end
    end
  end

  describe '.update_error' do
    before do
      allow(Workflow::NextStepService).to receive(:enqueue_next_steps)
    end

    let(:step) { create(:workflow_step) }

    it 'updates the step with error message/text' do
      expect do
        described_class.update_error(druid: step.druid, workflow_name: step.workflow, process: step.process,
                                     error_msg: 'failed to do the thing', error_text: 'box1.foo.edu')
      end
        .to change { step.reload.status }.from('waiting').to('error')
        .and change(step, :error_msg).to('failed to do the thing')
        .and change(step, :error_txt).to('box1.foo.edu')
      expect(Workflow::NextStepService).to have_received(:enqueue_next_steps).with(step:)
    end
  end
end
