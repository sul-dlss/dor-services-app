require 'rails_helper'

RSpec.describe WorkflowsController do
  before do
    login
  end

  it "GET of /workflows/{wfname}/initial returns the an initial instance of the workflow's xml" do
    expect(Dor::WorkflowObject).to receive(:initial_workflow).with('accessionWF') { <<-XML
      <workflow id="accessionWF">
        <process name="start-accession" status="completed" attempts="1" lifecycle="submitted"/>
        <process name="content-metadata" status="waiting"/>
      </workflow>
      XML
    }

    get :initial, params: { wf_name: 'accessionWF' }

    expect(response.content_type).to eq('application/xml')
    expect(response.body).to match(/start-accession/)
  end

  describe 'workflow archiving' do
    let(:item) { AssembleableVersionableItem.new.tap { |x| x.pid = 'druid:aa123bb4567' } }

    before do
      allow(Dor).to receive(:find).with(item.pid).and_return(item)
    end

    it 'POSTing to /objects/{druid}/workflows/{wfname}/archive archives a workflow for a given druid and repository' do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '1')
      post :archive, params: { object_id: item.pid, id: 'accessionWF' }
      expect(response.body).to eq('accessionWF version 1 archived')
    end

    it 'POSTing to /objects/{druid}/workflows/{wfname}/archive/{ver_num} archives a workflow with a specic version' do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '3')
      post :archive, params: { object_id: item.pid, id: 'accessionWF', ver_num: 3 }
      expect(response.body).to eq('accessionWF version 3 archived')
    end

    it 'checks if all rows are complete before archiving' do
      skip 'Maybe check should be in the gem'
    end
  end
end
