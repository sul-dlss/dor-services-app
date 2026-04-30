# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LaneSupport do
  describe '.lane_for' do
    context 'when lane_id is "low"' do
      it 'returns :low' do
        expect(described_class.lane_for('low')).to eq(:low)
      end
    end

    context 'when lane_id is "high"' do
      it 'returns :high' do
        expect(described_class.lane_for('high')).to eq(:high)
      end
    end

    context 'when lane_id is unrecognized' do
      it 'returns :default' do
        expect(described_class.lane_for('unknown')).to eq(:default)
      end
    end

    context 'when lane_id is nil' do
      it 'returns :default' do
        expect(described_class.lane_for(nil)).to eq(:default)
      end
    end

    context 'when a prefix is provided' do
      it 'prepends the prefix to the lane' do
        expect(described_class.lane_for('low', prefix: 'robots')).to eq(:robots_low)
      end

      it 'prepends the prefix to the default lane' do
        expect(described_class.lane_for('unknown', prefix: 'robots')).to eq(:robots_default)
      end
    end
  end
end
