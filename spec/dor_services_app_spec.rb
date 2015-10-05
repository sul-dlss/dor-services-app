require 'spec_helper'

class AssembleableVersionableItem < ActiveFedora::Base
  include Dor::Assembleable
  include Dor::Versionable
  attr_accessor :pid
end

describe Dor::DorServicesApi do
  def app
    @app ||= Dor::DorServicesApi
  end

  let(:item) {AssembleableVersionableItem.new}

  before(:each) do
    allow(ActiveFedora).to receive(:fedora).and_return(double('frepo').as_null_object)
    clean_workspace
    item.pid = 'druid:aa123bb4567'
    allow(Dor::Item).to receive(:find).and_return(item)
  end

  after(:all) {clean_workspace}

  it "handles simple ping requests to /about" do
    get '/v1/about'
    expect(last_response).to be_ok
    expect(last_response.body).to match(/version: \d\..*$/)
  end

  describe "initialize_workspace" do
    before(:each) {login}

    it "creates a druid tree in the dor workspace for the passed in druid" do
      post "/v1/objects/#{item.pid}/initialize_workspace"
      expect(File).to be_directory(TEST_WORKSPACE + '/aa/123/bb/4567')
    end

    it "creates a link in the dor workspace to the path passed in as source" do
      post "/v1/objects/#{item.pid}/initialize_workspace", :source => '/some/path'
      expect(File).to be_symlink(TEST_WORKSPACE + '/aa/123/bb/4567/aa123bb4567')
    end

    context "error handling" do
      before(:each) do
        druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
        druid.mkdir
      end

      it "returns a 409 Conflict http status code when the link/directory already exists" do
        post "/v1/objects/#{item.pid}/initialize_workspace"

        expect(last_response.status).to eq(409)
        expect(last_response.body).to match(/The directory already exists/)
      end

      it "returns a 409 Conflict http status code when the workspace already exists with different content" do
        post "/v1/objects/#{item.pid}/initialize_workspace", :source => '/some/path'

        expect(last_response.status).to eq(409)
        expect(last_response.body).to match(/Unable to create link, directory already exists/)
      end
    end

  end

  describe '/release_tags' do
    before(:each) {login}

    it 'adds a release tag when posted to with false' do
      expect(item).to receive(:add_release_node).with(false, {:to => 'searchworks', :who => 'carrickr', :what=>'self', :release=>false} )
      expect(item).to receive(:save)
      post "/v1/objects/#{item.pid}/release_tags", %( {"to":"searchworks","who":"carrickr","what":"self","release":false} )

      expect(last_response.status).to eq(201)
    end

    it 'adds a release tag when posted to with true' do
      expect(item).to receive(:add_release_node).with(true, {:to => 'searchworks', :who => 'carrickr', :what=>'self', :release=>true} )
      expect(item).to receive(:save)
      post "/v1/objects/#{item.pid}/release_tags", %( {"to":"searchworks","who":"carrickr","what":"self","release":true} )

      expect(last_response.status).to eq(201)
    end

    it 'errors when posted to with an invalid release attribute' do
      post "/v1/objects/#{item.pid}/release_tags", %( {"to":"searchworks","who":"carrickr","what":"self","release":"seven"} )
      expect(last_response.status).to eq(400)
    end

    it 'errors when posted to with a missing release attribute' do
      post "/v1/objects/#{item.pid}/release_tags", %( {"to":"searchworks","who":"carrickr","what":"self"} )
      expect(last_response.status).to eq(400)
    end
  end

  describe "apo-workflow intialization" do
    before(:each) {login}

    it "initiates accessionWF via obj.initiate_apo_workflow" do
      expect(item).to receive(:initiate_apo_workflow).with('assemblyWF')

      post "/v1/objects/#{item.pid}/apo_workflows/assemblyWF"
    end

    it "handles workflow names without 'WF' appended to the end" do
      expect(item).to receive(:initiate_apo_workflow).with('accessionWF')

      post "/v1/objects/#{item.pid}/apo_workflows/accession"
    end
  end

  describe "object registration" do
    before(:each) {login}

    context "error handling" do
      it "returns a 409 error with location header when an object already exists" do
        allow(Dor::RegistrationService).to receive(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))

        post "/v1/objects", :some => 'param'
        expect(last_response.status).to eq(409)
        expect(last_response.headers['location']).to match(/\/fedora\/objects\/druid:existing123obj/)
      end

      it "logs all unhandled exceptions" do
        allow(Dor::RegistrationService).to receive(:register_object).and_raise(Exception.new("Testing Exception Logging"))
        expect(LyberCore::Log).to receive(:exception)

        post "/v1/objects", :some => 'param'
        expect(last_response.status).to eq(500)
      end
    end
  end

  describe "versioning" do
    before(:each) {login}

    describe "/versions/current" do
      it "returns the latest version for an object" do
        get "/v1/objects/#{item.pid}/versions/current"

        expect(last_response.body).to eq('1')
      end
    end

    describe "/versions/current/close" do
      it "closes the current version when posted to" do
        expect(item).to receive(:close_version)
        post "/v1/objects/#{item.pid}/versions/current/close"

        expect(last_response.body).to match(/version 1 closed/)
      end

      it "forwards optional params to the Dor::Item#close_version method" do
        expect(item).to receive(:close_version).with( {:description => 'some text', :significance => :major} )
        post "/v1/objects/#{item.pid}/versions/current/close", %( {"description": "some text", "significance": "major"} )

        expect(last_response.body).to match(/version 1 closed/)
      end
    end

    describe "/versions" do
      it "opens a new object version when posted to" do
        expect(Dor::WorkflowService).to receive(:get_lifecycle).with('dor', item.pid, 'accessioned').and_return(true)
        expect(Dor::WorkflowService).to receive(:get_active_lifecycle).with('dor', item.pid, 'submitted').and_return(nil)
        expect(Dor::WorkflowService).to receive(:get_active_lifecycle).with('dor', item.pid, 'opened').and_return(nil)

        expect(Sdr::Client).to receive(:current_version).and_return(1)
        expect(item).to receive(:initialize_workflow).with('versioningWF')
        allow(item).to receive(:save)
        post "/v1/objects/#{item.pid}/versions"

        expect(last_response.body).to eq('2')
      end
    end

  end

  describe "workflow archiving" do
    before(:each) {login}

    it "POSTing to /objects/{druid}/workflows/{wfname}/archive archives a workflow for a given druid and repository" do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '1')
      post "/v1/objects/#{item.pid}/workflows/accessionWF/archive"

      expect(last_response.body).to eq('accessionWF version 1 archived')
    end

    it "POSTing to /objects/{druid}/workflows/{wfname}/archive/{ver_num} archives a workflow with a specic version" do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '3')
      post "/v1/objects/#{item.pid}/workflows/accessionWF/archive/3"

      expect(last_response.body).to eq('accessionWF version 3 archived')
    end

    it "checks if all rows are complete before archiving" do
      skip "Maybe check should be in the gem"
    end
  end

  describe "workflow definitions" do
    before(:each) {login}

    it "GET of /workflows/{wfname}/initial returns the an initial instance of the workflow's xml" do
      expect(Dor::WorkflowObject).to receive(:initial_workflow).with('accessionWF') { <<-XML
        <workflow id="accessionWF">
          <process name="start-accession" status="completed" attempts="1" lifecycle="submitted"/>
          <process name="content-metadata" status="waiting"/>
        </workflow>
        XML
       }

      get '/v1/workflows/accessionWF/initial'

      expect(last_response.content_type).to eq('application/xml')
      expect(last_response.body).to match(/start-accession/)
    end

  end
end
