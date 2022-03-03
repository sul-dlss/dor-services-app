# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SuriService do
  describe '.mint_id' do
    before do
      allow(Faraday).to receive(:post).and_return(instance_double(Faraday::Response, body: druid))
    end

    context 'when request returns a valid druid' do
      let(:druid) { 'bc123df4567' }

      it 'returns a bare druid string' do
        expect(described_class.mint_id).to eq("druid:#{druid}")
      end
    end

    context 'when request returns a malformed druid' do
      let(:druid) { 'foobar' }

      it 'raises an error' do
        expect { described_class.mint_id }.to raise_error(
          described_class::MalformedDruidError,
          "SURI service returned a malformed druid: druid:#{druid}"
        )
      end
    end

    context 'when request returns nil' do
      let(:druid) { nil }

      it 'raises an error' do
        expect { described_class.mint_id }.to raise_error(
          described_class::MalformedDruidError,
          'SURI service returned a malformed druid: druid:'
        )
      end
    end
  end
end
