# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectUpdated do
  subject(:publish) { described_class.publish(model:, created_at:, modified_at:) }

  let(:data) { { data: '455' } }
  let(:created_at) { '04 Feb 2022' }
  let(:modified_at) { '04 Feb 2022' }
  let(:channel) { instance_double(Notifications::RabbitChannel, topic:) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }
  let(:message) { "{\"model\":{\"data\":\"455\"},\"created_at\":\"#{created_at.to_datetime.httpdate}\",\"modified_at\":\"#{modified_at.to_datetime.httpdate}\"}" }

  context 'when RabbitMQ is enabled' do
    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    context 'when called with a DRO' do
      let(:model) do
        instance_double(Cocina::Models::DRO,
                        externalIdentifier: 'druid:123', to_h: data)
      end

      before do
        allow(AdministrativeTags).to receive(:project).and_return(['h2'])
      end

      it 'is successful' do
        publish
        expect(topic).to have_received(:publish).with(message, routing_key: 'h2')
        expect(AdministrativeTags).to have_received(:project).with(identifier: 'druid:123')
      end
    end

    context 'when called with an AdminPolicy' do
      let(:model) { build(:admin_policy) }

      before do
        allow(model).to receive(:to_h).and_return(data)
      end

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
                        externalIdentifier: 'druid:123', to_h: data)
      end

      it 'does not receive a message' do
        publish
        expect(topic).not_to have_received(:publish)
      end
    end
  end
end
