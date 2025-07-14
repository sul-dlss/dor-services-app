# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowTemplateLoader do
  let(:loader) { described_class.new(workflow_name) }

  let(:workflow_name) { 'assemblyWF' }

  describe '#workflow_filepath' do
    let(:workflow_filepath) { loader.workflow_filepath }

    it 'finds filepath' do
      expect(workflow_filepath).to eq("config/workflows/#{workflow_name}.xml")
    end
  end

  describe '#exists?' do
    context 'when file exists' do
      it 'returns true' do
        expect(loader.exists?).to be true
      end
    end

    context 'when file does not exist' do
      let(:workflow_name) { 'xassemblyWF' }

      it 'returns false' do
        expect(loader.exists?).to be false
      end
    end
  end

  describe '#load' do
    context 'when file exists' do
      it 'returns file as string' do
        expect(loader.load).to start_with('<?xml')
      end
    end

    context 'when file does not exist' do
      let(:workflow_name) { 'xassemblyWF' }

      it 'returns nil' do
        expect(loader.load).to be_nil
      end
    end
  end

  describe '#load_as_xml' do
    context 'when file exists' do
      it 'returns file as XML' do
        expect(loader.load_as_xml).to be_a(Nokogiri::XML::Document)
      end
    end

    context 'when file does not exist' do
      let(:workflow_name) { 'xassemblyWF' }

      it 'returns nil' do
        expect(loader.load_as_xml).to be_nil
      end
    end
  end
end
