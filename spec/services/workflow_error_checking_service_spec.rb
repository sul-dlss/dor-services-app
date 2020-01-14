# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowErrorCheckingService do
  subject(:service) { described_class.new(item: item, version: item.current_version) }

  let(:item) { instance_double(Dor::Item, id: 'druid:child1', current_version: '1') }

  describe '.check' do
    let(:instance) { instance_double(described_class, check: []) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates an instance of the class and calls #check' do
      described_class.check(item: item, version: item.current_version)
      expect(instance).to have_received(:check).once
    end
  end

  describe '.new' do
    it 'has an item attr' do
      expect(service.item).to eq(item)
    end

    it 'has a version attr' do
      expect(service.version).to eq(item.current_version)
    end
  end

  describe '#check' do
    subject { service.check }

    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_routes: workflow_routes) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
    let(:workflows_response) do
      instance_double(Dor::Workflow::Response::Workflows, errors_for: errors)
    end

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    end

    context 'when one or more workflows contain errors' do
      let(:errors) { ['the first error', 'the second error'] }

      it { is_expected.to eq ['the first error', 'the second error'] }
    end

    context 'when no workflows contain errors' do
      let(:errors) { [] }

      it { is_expected.to be_empty }
    end
  end
end
