# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::TemplateLoader do
  let(:loader) { described_class.new(workflow_name) }

  let(:workflow_name) { 'assemblyWF' }

  describe '#workflow_filepath' do
    let(:workflow_filepath) { loader.workflow_filepath }

    it 'finds filepath' do
      expect(workflow_filepath).to eq(Rails.root.join("config/workflows/#{workflow_name}.xml").to_s)
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

  describe '#load_as_xml' do
    context 'when file exists' do
      it 'returns file as XML' do
        expect(loader.load_as_xml).to be_a(Nokogiri::XML::Document)
        # Loading against does not reread the file
        allow(File).to receive(:read).and_call_original
        expect(loader.load_as_xml).to be_a(Nokogiri::XML::Document)
        expect(described_class.load_as_xml(workflow_name)).to be_a(Nokogiri::XML::Document)
        expect(File).not_to have_received(:read)
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
