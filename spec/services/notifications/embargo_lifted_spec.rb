# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::EmbargoLifted do
  subject(:publish) { described_class.publish(model: model) }

  let(:druid) { 'druid:bc123df4567' }
  let(:channel) { instance_double(Notifications::RabbitChannel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  let(:model) { build(:dro_with_metadata, id: druid) }

  context 'when RabbitMQ is enabled' do
    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    context 'when called with a DROWithMetadata' do
      before do
        allow(AdministrativeTags).to receive(:project).and_return(['h2'])
      end

      it 'strips metadata and is successful' do
        publish
        expected = { model: Cocina::Models.without_metadata(model).to_h }.to_json
        expect(topic).to have_received(:publish).with(expected, routing_key: 'h2')
        expect(AdministrativeTags).to have_received(:project).with(identifier: druid)
      end
    end

    context 'when called with an AdminPolicyWithMetadata' do
      let(:model) { build(:admin_policy, id: druid) }

      it 'strips metadata and is successful' do
        publish
        expected = { model: Cocina::Models.without_metadata(model).to_h }.to_json
        expect(topic).to have_received(:publish).with(expected, routing_key: 'SDR')
      end
    end
  end

  context 'when RabbitMQ is disabled' do
    before do
      allow(Settings.rabbitmq).to receive(:enabled).and_return(false)
    end

    context 'when called with a DRO' do
      it 'does not receive a message' do
        publish
        expect(topic).not_to have_received(:publish)
      end
    end
  end
end
