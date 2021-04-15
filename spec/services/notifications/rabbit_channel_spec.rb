# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::RabbitChannel do
  let(:bunny) { instance_double(Bunny::Session, start: true, create_channel: channel) }
  let(:channel) { instance_double(Bunny::Channel, topic: topic) }
  let(:topic) { instance_double(Bunny::Exchange) }

  before do
    allow(Bunny).to receive(:new).and_return(bunny)
  end

  describe '#topic' do
    subject { described_class.instance.topic('sdr.whatever') }

    it { is_expected.to eq topic }
  end
end
