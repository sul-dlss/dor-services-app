# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectDeleted do
  subject(:publish) { described_class.publish(model: model, deleted_at: deleted_at) }

  let(:deleted_at) { Time.zone.now }
  let(:administrative) do
    instance_double(Cocina::Models::Administrative, partOfProject: 'h2')
  end

  let(:channel) { instance_double(Notifications::RabbitChannel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }
  let(:message) { "{\"druid\":\"druid:123\",\"deleted_at\":\"#{deleted_at.to_datetime.httpdate}\"}" }

  before do
    allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
  end

  context 'when called with a DRO' do
    let(:model) do
      instance_double(Cocina::Models::DRO,
                      externalIdentifier: 'druid:123', administrative: administrative)
    end

    it 'is successful' do
      publish
      expect(topic).to have_received(:publish).with(message, routing_key: 'h2')
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
