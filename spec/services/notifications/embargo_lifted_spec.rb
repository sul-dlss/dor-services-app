# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::EmbargoLifted do
  subject(:publish) { described_class.publish(model: model) }

  let(:druid) { 'druid:bc123df4567' }
  let(:channel) { instance_double(Notifications::RabbitChannel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  let(:model) do
    Cocina::Models::DROWithMetadata.new(externalIdentifier: druid,
                                        lock: "#{druid}=0",
                                        created: 'Mon, 17 Jun 2019 15:47:11 +0000',
                                        modified: 'Mon, 17 Jun 2019 15:47:11 +0000',
                                        type: Cocina::Models::ObjectType.book,
                                        access: {},
                                        structural: {},
                                        label: 'cool',
                                        version: 1,
                                        description: {
                                          title: [{ value: 'cool' }],
                                          purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                        },
                                        administrative: {
                                          hasAdminPolicy: 'druid:dd999df4567'
                                        },
                                        identification: {
                                          sourceId: 'some:source_id'
                                        })
  end

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
        expected = { model: model.to_h.except(:created, :modified, :lock) }.to_json
        expect(topic).to have_received(:publish).with(expected, routing_key: 'h2')
        expect(AdministrativeTags).to have_received(:project).with(identifier: druid)
      end
    end

    context 'when called with an AdminPolicyWithMetadata' do
      let(:model) do
        Cocina::Models::AdminPolicyWithMetadata.new(externalIdentifier: druid,
                                                    lock: "#{druid}=0",
                                                    created: 'Mon, 17 Jun 2019 15:47:11 +0000',
                                                    modified: 'Mon, 17 Jun 2019 15:47:11 +0000',
                                                    administrative: {
                                                      hasAdminPolicy: 'druid:gg123vx9393',
                                                      hasAgreement: 'druid:bb008zm4587',
                                                      accessTemplate: { view: 'world', download: 'world' }
                                                    },
                                                    version: 1,
                                                    label: 'just an apo',
                                                    type: Cocina::Models::ObjectType.admin_policy)
      end

      it 'strips metadata and is successful' do
        publish
        expected = { model: model.to_h.except(:created, :modified, :lock) }.to_json
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
