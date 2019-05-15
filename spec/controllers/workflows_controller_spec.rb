# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowsController do
  before do
    login
    allow(Honeybadger).to receive(:notify)
  end

  it "GET of /workflows/{wfname}/initial returns the an initial instance of the workflow's xml" do
    expect(Dor::WorkflowObject).to receive(:initial_workflow).with('accessionWF') {
      <<-XML
      <workflow id="accessionWF">
        <process name="start-accession" status="completed" attempts="1" lifecycle="submitted"/>
        <process name="content-metadata" status="waiting"/>
      </workflow>
      XML
    }

    get :initial, params: { wf_name: 'accessionWF' }

    expect(response.content_type).to eq('application/xml')
    expect(response.body).to match(/start-accession/)
    expect(Honeybadger).to have_received(:notify).with(/Call to deprecated API/)
  end
end
