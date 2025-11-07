# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectCreated do
  subject(:publish) { described_class.publish(model: model.to_cocina_with_metadata) }

  let(:created_at) { '04 Feb 2022' }
  let(:updated_at) { '04 Feb 2022' }
  let(:message) do
    "{\"model\":#{model_json},\"created_at\":\"Fri, 04 Feb 2022 00:00:00 GMT\",\"modified_at\":\"Fri, 04 Feb 2022 00:00:00 GMT\"}" # rubocop:disable Layout/LineLength
  end
  let(:model_json) { model.to_cocina.to_json }

  let(:channel) { instance_double(Notifications::RabbitChannel, topic:) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  let(:model) do
    create(:repository_object, :with_repository_object_version, object_type, created_at:) do |repo_obj|
      repo_obj.head_version.update(updated_at:)
    end
  end

  let(:object_type) { :dro }

  context 'when RabbitMQ is enabled' do
    before do
      allow(Notifications::RabbitChannel).to receive(:instance).and_return(channel)
      allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
    end

    context 'when called with a DRO' do
      before do
        allow(AdministrativeTags).to receive(:project).and_return(['h2'])
      end

      it 'is successful' do
        publish
        expect(topic).to have_received(:publish).with(message, routing_key: 'h2')
        expect(AdministrativeTags).to have_received(:project).with(identifier: model.external_identifier)
      end
    end

    context 'when called with an AdminPolicy' do
      let(:object_type) { :admin_policy }

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
      it 'does not receive a message' do
        publish
        expect(topic).not_to have_received(:publish)
      end
    end
  end
end
