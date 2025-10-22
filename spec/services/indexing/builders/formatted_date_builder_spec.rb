# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Builders::FormattedDateBuilder do
  describe '.build' do
    subject(:build) { described_class.build(date) }

    context 'with a valid date' do
      let(:date) { DateTime.parse('2025-10-22T13:05:00Z') }

      it 'returns the date in the correct format' do
        expect(build).to eq('2025-10-22 06:05:00 AM')
      end
    end

    context 'with a nil date' do
      let(:date) { nil }

      it 'returns nil' do
        expect(build).to be_nil
      end
    end
  end
end
