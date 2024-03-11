# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagLabel do
  describe 'tag format validation' do
    context 'with invalid values' do
      ['Configured With', 'Registered By:mjg'].each do |tag|
        subject(:label) { described_class.new(tag:) }

        it { is_expected.not_to be_valid }
      end
    end

    context 'with valid values' do
      ['Registered By : mjgiarlo', 'Process : Content Type : Map'].each do |tag|
        subject(:label) { described_class.new(tag:) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'tag format normalization' do
    subject(:label) { described_class.new(tag:) }

    let(:expected_tag) { 'Registered By : mjgiarlo' }

    context 'with leading whitespace' do
      let(:tag) { '   Registered By : mjgiarlo' }

      it 'removes leading whitespace' do
        expect(label.tag).to eq(expected_tag)
      end
    end

    context 'with trailing whitespace' do
      let(:tag) { 'Registered By : mjgiarlo   ' }

      it 'removes trailing whitespace' do
        expect(label.tag).to eq(expected_tag)
      end
    end

    context 'without leading and trailing whitespace' do
      let(:tag) { 'Registered By : mjgiarlo' }

      it 'leaves the tag as is' do
        expect(label.tag).to eq(expected_tag)
      end
    end
  end
end
