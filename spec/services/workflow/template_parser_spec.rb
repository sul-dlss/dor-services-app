# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::TemplateParser do
  let(:xml) { Workflow::TemplateLoader.load_as_xml('accessionWF') }
  let(:wf_parser) do
    described_class.new(xml)
  end

  describe '#processes' do
    subject(:processes) { wf_parser.processes }

    it 'returns a list of process structs' do
      expect(processes.length).to eq ACCESSION_WF_STEP_COUNT
      expect(processes).to all(be_an_instance_of(Workflow::TemplateParser::Process))
    end
  end
end
