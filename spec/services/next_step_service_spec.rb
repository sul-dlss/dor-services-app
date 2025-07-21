# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NextStepService do
  describe '.enqueue_next_steps' do
    subject(:next_steps) { described_class.enqueue_next_steps(step:) }

    context "when there is a step that isn't complete" do
      let(:step) do
        create(:workflow_step,
               process: 'start-accession',
               version: 1,
               status: 'completed',
               active_version: true)
      end

      let!(:ready) do
        create(:workflow_step,
               druid: step.druid,
               process: 'stage',
               version: 1,
               status: 'waiting',
               active_version: true)
      end

      before do
        # This record does not have the prerequisites met, so it shouldn't appear in the results
        create(:workflow_step,
               druid: step.druid,
               process: 'publish',
               version: 1,
               status: 'waiting',
               active_version: true)
        allow(QueueService).to receive(:enqueue)
      end

      it 'returns a list of unblocked statuses' do
        expect(next_steps).to eq [ready]
        expect(QueueService).to have_received(:enqueue).with(ready)
      end
    end

    context "when it's the hydrusAssemblyWF" do
      let(:step) do
        create(:workflow_step,
               process: 'start-deposit',
               workflow: 'hydrusAssemblyWF',
               version: 1,
               status: 'completed',
               active_version: true)
      end

      before do
        create(:workflow_step,
               druid: step.druid,
               process: 'submit',
               workflow: 'hydrusAssemblyWF',
               version: 1,
               status: 'waiting',
               active_version: true)
      end

      it "returns no statuses (they're all skip-queue)" do
        expect(next_steps).to eq []
      end
    end
  end
end
