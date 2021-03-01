# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::ObjectCreated do
  subject(:publish) { described_class.publish(model: model) }

  let(:data) { { data: '455' } }
  let(:administrative) do
    instance_double(Cocina::Models::Administrative, partOfProject: 'h2')
  end

  let(:bunny) { instance_double(Bunny::Session, start: true, create_channel: channel) }
  let(:channel) { instance_double(Bunny::Channel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange, publish: true) }

  before do
    allow(Bunny).to receive(:new).and_return(bunny)
  end

  context 'when called with a DRO' do
    let(:model) do
      instance_double(Cocina::Models::DRO,
                      externalIdentifier: 'druid:123', administrative: administrative, to_h: data)
    end

    it 'is successful' do
      publish
      expect(topic).to have_received(:publish).with('{"model":{"data":"455"}}', routing_key: 'h2')
    end
  end

  context 'when called with an AdminPolicy' do
    let(:model) do
      Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc123dg9393',
                                      administrative: {
                                        hasAdminPolicy: 'druid:gg123vx9393'
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
