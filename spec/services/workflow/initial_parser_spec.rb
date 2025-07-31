# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::InitialParser do
  let(:xml) do
    workflow_template = Workflow::TemplateLoader.load_as_xml('accessionWF')
    Workflow::Transformer.initial_workflow(workflow_template)
  end
  let(:wf_parser) do
    described_class.new(xml)
  end

  describe '#workflow_id' do
    subject(:workflow_id) { wf_parser.workflow_id }

    it { is_expected.to eq 'accessionWF' }

    context 'when the data is missing an id' do
      let(:xml) do
        Nokogiri::XML(
          <<~XML
            <?xml version="1.0"?>
            <workflow />
          XML
        )
      end

      it 'raises an error' do
        expect do
          workflow_id
        end.to raise_error('Workflow did not provide a required @id attribute')
      end
    end
  end

  describe '#processes' do
    subject(:processes) { wf_parser.processes }

    it 'is a list of ProcessParsers' do
      expect(processes).to all be_instance_of ProcessParser
      expect(processes.size).to eq ACCESSION_WF_STEP_COUNT
    end
  end
end
