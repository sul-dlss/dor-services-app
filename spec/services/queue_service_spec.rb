# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QueueService do
  let(:service) { described_class.new step }

  let(:step) { create(:workflow_step, workflow: 'assemblyWF', process: 'jp2-create') }

  describe '#enqueue' do
    before do
      allow(ROBOT_SIDEKIQ_CLIENT).to receive(:push).and_return('123')
    end

    context 'when JP2 robot (special case)' do
      let(:step) { create(:workflow_step, workflow: 'assemblyWF', process: 'jp2-create') }

      it 'enqueues to Sidekiq' do
        service.enqueue
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).with('queue' => 'assemblyWF_jp2',
                                                                  'class' => 'Robots::DorRepo::Assembly::Jp2Create',
                                                                  'args' => [step.druid])
      end
    end

    context 'when DSA robot (special case)' do
      let(:step) { create(:workflow_step, workflow: 'accessionWF', process: 'publish') }

      it 'enqueues to Sidekiq' do
        service.enqueue
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).with('queue' => 'accessionWF_default_dsa',
                                                                  'class' => 'Robots::DorRepo::Accession::Publish',
                                                                  'args' => [step.druid])
      end
    end

    context 'when DorRepo classes' do
      let(:step) { create(:workflow_step, workflow: 'accessionWF', process: 'technical-metadata') }

      it 'enqueues to Sidekiq' do
        service.enqueue
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).with('queue' => 'accessionWF_default',
                                                                  'class' => 'Robots::DorRepo::Accession::TechnicalMetadata',
                                                                  'args' => [step.druid])
      end
    end

    context 'when SdrRepo classes' do
      let(:step) { create(:workflow_step, workflow: 'preservationIngestWF', process: 'transfer-object') }

      it 'enqueues to Sidekiq' do
        service.enqueue
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).with('queue' => 'preservationIngestWF_default',
                                                                  'class' => 'Robots::SdrRepo::PreservationIngest::TransferObject',
                                                                  'args' => [step.druid])
      end
    end

    context 'when .push returns nil' do
      before do
        allow(ROBOT_SIDEKIQ_CLIENT).to receive(:push).and_return(nil)
      end

      let(:step) { create(:workflow_step, workflow: 'assemblyWF', process: 'jp2-create') }

      it 'raises' do
        expect { service.enqueue }.to raise_error(/Enqueueing/)
      end
    end

    context 'when Redis::CannotConnectError is raised' do
      before do
        allow(ROBOT_SIDEKIQ_CLIENT).to receive(:push).and_raise(Redis::CannotConnectError)
        allow(service).to receive(:sleep)
      end

      let(:step) { create(:workflow_step, workflow: 'assemblyWF', process: 'jp2-create') }

      it 'tries up to 4 times' do
        expect { service.enqueue }.to raise_error(Redis::CannotConnectError)
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).exactly(4).times
      end
    end

    context 'when Redis::CannotConnectError is raised once' do
      before do
        allow(ROBOT_SIDEKIQ_CLIENT).to receive(:push).and_invoke(
          ->(*) { raise Redis::CannotConnectError, 'Connection refused' }, ->(*) { '123' }
        )
        allow(service).to receive(:sleep)
      end

      let(:step) { create(:workflow_step, workflow: 'assemblyWF', process: 'jp2-create') }

      it 'retries and then succeeds' do
        service.enqueue
        expect(ROBOT_SIDEKIQ_CLIENT).to have_received(:push).exactly(2).times
      end
    end
  end

  describe '#class_name' do
    let(:class_name) { service.send(:class_name) }

    it 'create correct class_name' do
      expect(class_name).to eq('Robots::DorRepo::Assembly::Jp2Create')
    end
  end
end
