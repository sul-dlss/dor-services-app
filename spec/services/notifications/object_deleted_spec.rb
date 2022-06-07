# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectDeleted do
  subject(:publish) { described_class.publish(model:, deleted_at:) }

  let(:deleted_at) { Time.zone.now }

  let(:channel) { instance_double(Notifications::RabbitChannel, topic:) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }
  let(:message) { "{\"druid\":\"druid:123\",\"deleted_at\":\"#{deleted_at.to_datetime.httpdate}\"}" }

  context 'when RabbitMQ is enabled' do
    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    context 'when called with a DRO' do
      before do
        allow(AdministrativeTags).to receive(:project).and_return(['h2'])
      end

      let(:model) do
        instance_double(Cocina::Models::DRO,
                        externalIdentifier: 'druid:123')
      end

      it 'is successful' do
        publish
        expect(topic).to have_received(:publish).with(message, routing_key: 'h2')
        expect(AdministrativeTags).to have_received(:project).with(identifier: 'druid:123')
      end
    end

    context 'when called with an AdminPolicy' do
      let(:model) { instance_double(Cocina::Models::AdminPolicy, externalIdentifier: 'druid:123', is_a?: true) }

      it 'is successful' do
        publish
        expect(topic).to have_received(:publish).with(message, routing_key: 'SDR')
      end
    end
  end

  context 'when RabbitMQ is disabled' do
    before do
      allow(Settings.rabbitmq).to receive(:enabled).and_return(false)
    end

    context 'when called with a DRO' do
      let(:model) do
        instance_double(Cocina::Models::DRO,
                        externalIdentifier: 'druid:123')
      end

      it 'does not receive a message' do
        publish
        expect(topic).not_to have_received(:publish)
      end
    end
  end
end
