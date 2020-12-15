# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::ValueURI do
  describe '.sniff' do
    before do
      allow(Honeybadger).to receive(:notify)
    end

    context 'with a nil uri' do
      let(:uri) { nil }

      it 'returns the uri and does not alert' do
        expect(described_class.sniff(uri)).to eq(uri)
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context 'with a string uri that starts with supported prefix' do
      let(:uri) { 'http://foo.example.edu' }

      it 'returns the uri and does not alert' do
        expect(described_class.sniff(uri)).to eq(uri)
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context 'with a string uri that does not start with supported prefix' do
      let(:uri) { '(OCoLC)fst01204289' }

      it 'returns the uri and sends an alert' do
        expect(described_class.sniff(uri)).to eq(uri)
        expect(Honeybadger).to have_received(:notify).with("[DATA ERROR] Value URI has unexpected value: #{uri}", tags: 'data_error').once
      end
    end
  end
end
