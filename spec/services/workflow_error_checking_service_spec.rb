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
    let(:workflow_client) { instance_double(Dor::Workflow::Client, all_workflows_xml: xml) }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    end

    context 'when one or more workflows contain errors' do
      let(:xml) do
        <<~XML
          <workflows objectId="#{item.id}">
            <workflow id="accessionWF" objectId="#{item.id}" repository="dor">
              <process name="foo1" version="2" status="completed"/>
              <process name="foo2" version="2" status="completed"/>
              <process name="foo3" version="2" status="completed"/>
              <process name="foo4" version="2" status="completed"/>
              <process name="foo5" version="2" status="completed"/>
              <process name="foo1" version="1" status="error" errorMessage="the first error"/>
              <process name="foo2" version="1" status="waiting"/>
              <process name="foo3" version="1" status="waiting"/>
              <process name="foo4" version="1" status="waiting"/>
              <process name="foo5" version="1" status="waiting"/>
            </workflow>
            <workflow id="foobarWF" objectId="#{item.id}" repository="dor">
              <process name="bar1" version="2" status="completed"/>
              <process name="bar2" version="2" status="completed"/>
              <process name="bar3" version="2" status="completed"/>
              <process name="bar4" version="2" status="completed"/>
              <process name="bar5" version="2" status="completed"/>
              <process name="bar1" version="1" status="completed"/>
              <process name="bar2" version="1" status="completed"/>
              <process name="bar3" version="1" status="error" errorMessage="the second error"/>
              <process name="bar4" version="1" status="waiting"/>
              <process name="bar5" version="1" status="waiting"/>
            </workflow>
          </workflows>
        XML
      end

      it 'returns an array of error strings' do
        expect(service.check).to eq(['the first error', 'the second error'])
      end
    end

    context 'when no workflows contain errors' do
      let(:xml) do
        <<~XML
          <workflows objectId="#{item.id}">
            <workflow id="accessionWF" objectId="#{item.id}" repository="dor">
              <process name="foo1" version="2" status="completed"/>
              <process name="foo2" version="2" status="completed"/>
              <process name="foo3" version="2" status="completed"/>
              <process name="foo4" version="2" status="completed"/>
              <process name="foo5" version="2" status="completed"/>
              <process name="foo1" version="1" status="waiting"/>
              <process name="foo2" version="1" status="waiting"/>
              <process name="foo3" version="1" status="waiting"/>
              <process name="foo4" version="1" status="waiting"/>
              <process name="foo5" version="1" status="waiting"/>
            </workflow>
            <workflow id="foobarWF" objectId="#{item.id}" repository="dor">
              <process name="bar1" version="2" status="completed"/>
              <process name="bar2" version="2" status="completed"/>
              <process name="bar3" version="2" status="completed"/>
              <process name="bar4" version="2" status="completed"/>
              <process name="bar5" version="2" status="completed"/>
              <process name="bar1" version="1" status="completed"/>
              <process name="bar2" version="1" status="completed"/>
              <process name="bar3" version="1" status="completed"/>
              <process name="bar4" version="1" status="waiting"/>
              <process name="bar5" version="1" status="waiting"/>
            </workflow>
          </workflows>
        XML
      end

      it 'returns an empty array' do
        expect(service.check).to eq([])
      end
    end
  end
end
