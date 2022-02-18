# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectCreated do
  subject(:publish) { described_class.publish(model: model, created_at: created_at, modified_at: modified_at) }

  let(:data) { { data: '455' } }
  let(:created_at) { '04 Feb 2022' }
  let(:modified_at) { '04 Feb 2022' }
  let(:administrative) do
    instance_double(Cocina::Models::Administrative, partOfProject: 'h2')
  end
  let(:message) do
    "{\"model\":{\"data\":\"455\"},\"created_at\":\"#{created_at.to_datetime.httpdate}\",\"modified_at\":\"#{modified_at.to_datetime.httpdate}\"}"
  end

  let(:channel) { instance_double(Notifications::RabbitChannel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  context 'when RabbitMQ is enabled' do
    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    context 'when called with a DRO' do
      let(:model) do
        instance_double(Cocina::Models::DRO,
                        externalIdentifier: 'druid:123', administrative: administrative, to_h: data)
      end

      it 'is successful' do
        publish
        expect(topic).to have_received(:publish).with(message, routing_key: 'h2')
      end
    end

    context 'when called with an AdminPolicy' do
      let(:model) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc123dg9393',
                                        administrative: {
                                          hasAdminPolicy: 'druid:gg123vx9393',
                                          hasAgreement: 'druid:bb008zm4587'
                                        },
                                        version: 1,
                                        label: 'just an apo',
                                        type: Cocina::Models::Vocab.admin_policy)
      end

      it 'is successful' do
        publish
        expect(topic).not_to have_received(:publish)
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
                        externalIdentifier: 'druid:123', administrative: administrative, to_h: data)
      end

      it 'does not receive a message' do
        publish
        expect(topic).not_to have_received(:publish).with(message, routing_key: 'h2')
      end
    end
  end
end
