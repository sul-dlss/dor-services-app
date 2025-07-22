# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowTransformer do
  let(:transformer) { described_class.new workflow_template }

  let(:workflow_template) { WorkflowTemplateLoader.load_as_xml('accessionWF') }

  describe '#initial_workflow' do
    it 'transforms to initial workflow' do
      expect(transformer.initial_workflow.to_s).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <workflow id="accessionWF">
          <process name="start-accession" status="waiting" lifecycle="submitted"/>
          <process name="stage" status="waiting"/>
          <process name="technical-metadata" status="waiting"/>
          <process name="shelve" status="waiting"/>
          <process name="publish" status="waiting" lifecycle="published"/>
          <process name="update-doi" status="waiting"/>
          <process name="update-orcid-work" status="waiting"/>
          <process name="sdr-ingest-transfer" status="waiting"/>
          <process name="sdr-ingest-received" status="waiting" lifecycle="deposited"/>
          <process name="reset-workspace" status="waiting"/>
          <process name="end-accession" status="waiting" lifecycle="accessioned"/>
        </workflow>
      XML
    end
  end
end
