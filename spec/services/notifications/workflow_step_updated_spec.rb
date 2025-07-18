# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::WorkflowStepUpdated do
  subject(:publish) { described_class.publish(step:) }

  let(:step) do
    create(:workflow_step, status: 'completed', process: 'end-accession', workflow: 'accessionWF',
                           lifecycle: 'accessioned', updated_at: '2025-07-17T15:52:47+00:00')
  end

  let(:channel) { instance_double(Notifications::RabbitChannel, topic:) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  context 'when RabbitMQ is enabled' do
    let(:message) do
      {
        version: 1,
        note: nil,
        lifecycle: 'accessioned',
        laneId: 'default',
        elapsed: nil,
        attempts: 0,
        datetime: '2025-07-17T15:52:47+00:00',
        context: nil,
        status: 'completed',
        name: 'end-accession',
        action: 'workflow updated',
        druid: step.druid
      }.to_json
    end

    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    it 'is successful' do
      publish
      expect(topic).to have_received(:publish).with(message, routing_key: 'end-accession.completed')
    end
  end

  context 'when RabbitMQ is disabled' do
    before do
      allow(Settings.rabbitmq).to receive(:enabled).and_return(false)
    end

    it 'does not receive a message' do
      publish
      expect(topic).not_to have_received(:publish)
    end
  end
end
