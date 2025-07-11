# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowTemplateService do
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.template' do
    let(:template) { { name: 'example_workflow', steps: [] } }

    context 'when the template exists' do
      before do
        allow(workflow_client).to receive(:workflow_template).with('example_workflow').and_return(template)
      end

      it 'returns a workflow template by name' do
        expect(described_class.template(workflow_name: 'example_workflow')).to eq(template)
      end
    end

    context 'when the template does not exist' do
      before do
        allow(workflow_client).to receive(:workflow_template).with('non_existent').and_raise(Dor::MissingWorkflowException)
      end

      it 'raises an error if the template is not found' do
        expect { described_class.template(workflow_name: 'non_existent') }
          .to raise_error(WorkflowService::NotFoundException, "Workflow template 'non_existent' not found")
      end
    end
  end

  describe '.templates' do
    let(:templates) { ['template1', 'template2'] }

    before do
      allow(workflow_client).to receive(:workflow_templates).and_return(templates)
    end

    it 'returns a list of workflow template names' do
      expect(described_class.templates).to eq(templates)
    end
  end
end
