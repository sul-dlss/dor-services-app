# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Label do
  describe '#for' do
    let(:label) { described_class.for(item) }

    context 'when an object label' do
      let(:item) do
        Dor::Item.new(objectLabel: 'object label', label: 'label label')
      end

      it 'prefers object label' do
        expect(label).to eq('object label')
      end
    end

    context 'when no object label' do
      let(:item) do
        Dor::Item.new(label: 'label label')
      end

      it 'uses label' do
        expect(label).to eq('label label')
      end
    end

    context 'when label has a CR' do
      let(:item) do
        Dor::Item.new(label: "label\r label")
      end

      it 'removes it' do
        expect(label).to eq('label label')
      end
    end
  end
end
