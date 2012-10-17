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
    ActiveFedora.stub!(:fedora).and_return(stub('frepo').as_null_object)
    FileUtils.rm_rf Dir.glob('/tmp/dor/*')
    item.pid = 'druid:aa123bb4567'
    Dor::Item.stub!(:find).and_return(item)
  end
  
  after(:all) do
    FileUtils.rm_rf Dir.glob('/tmp/dor/*')
  end
  
  it "handles simple ping requests to /about" do
    get '/about'
    last_response.should be_ok
    last_response.body.should =~ /version: \d\..*$/
  end
  
  describe "initialize_workspace" do
    before(:each) {authorize 'dorAdmin', 'dorAdmin'}
      
    it "creates a druid tree in the dor workspace for the passed in druid" do
      post "/objects/#{item.pid}/initialize_workspace"
      File.should be_directory('/tmp/dor/aa/123/bb/4567')
    end
    
    it "creates a link in the dor workspace to the path passed in as source" do
      post "/objects/#{item.pid}/initialize_workspace", :source => '/tmp/stage/obj1'
      File.should be_symlink('/tmp/dor/aa/123/bb/4567/aa123bb4567')
    end
    
    context "error handling" do
      before(:each) do
        druid = DruidTools::Druid.new(item.pid, Dor::Config.stacks.local_workspace_root)
        druid.mkdir
      end
      
      it "returns a 409 Conflict http status code when the link/directory already exists" do
        post "/objects/#{item.pid}/initialize_workspace"
        
        last_response.status.should == 409
        last_response.body.should =~ /The directory already exists/
      end
      
      it "returns a 409 Conflict http status code when the workspace already exists with different content" do
        post "/objects/#{item.pid}/initialize_workspace", :source => '/some/path'
        
        last_response.status.should == 409
        last_response.body.should =~ /Unable to create link, directory already exists/
      end
    end
    
  end

  describe "apo-workflow intialization" do
    before(:each) {authorize 'dorAdmin', 'dorAdmin'}

    it "initiates accessionWF via obj.initiate_apo_workflow" do
      item.should_receive(:initiate_apo_workflow).with('assemblyWF')
      
      post "/objects/#{item.pid}/apo_workflows/assemblyWF"
    end
    
    it "handles workflow names without 'WF' appended to the end" do
      item.should_receive(:initiate_apo_workflow).with('accessionWF')
      
      post "/objects/#{item.pid}/apo_workflows/accession"
    end
  end

  describe "object registration" do
    before(:each) {authorize 'dorAdmin', 'dorAdmin'}

    context "error handling" do
      it "returns a 409 error with location header when an object already exists" do
        Dor::RegistrationService.stub!(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))

        post "/objects", :some => 'param'
        last_response.status.should == 409
        last_response.headers['location'].should == 'http://dor-dev.stanford.edu/fedora/objects/druid:existing123obj'
      end

      it "logs all unhandled exceptions" do
        Dor::RegistrationService.stub!(:register_object).and_raise(Exception.new("Testing Exception Logging"))
        LyberCore::Log.should_receive(:exception)

        post "/objects", :some => 'param'
        last_response.status.should == 500
      end
    end
  end

  describe "versioning" do
    before(:each) {authorize 'dorAdmin', 'dorAdmin'}
    
    describe "/versions/current" do
      it "returns the latest version for an object" do
        get "/objects/#{item.pid}/versions/current"

        last_response.body.should == '1'
      end
    end

    describe "/versions/current/close" do
      it "closes the current version when posted to" do
        item.should_receive(:close_version)
        post "/objects/#{item.pid}/versions/current/close"

        last_response.body.should =~ /version 1 closed/
      end
    end
    
    describe "/versions" do
      it "opens a new object version when posted to" do
        Dor::WorkflowService.should_receive(:get_lifecycle).with('dor', item.pid, 'accessioned').and_return(true)
        Dor::WorkflowService.should_receive(:get_active_lifecycle).with('dor', item.pid, 'opened').and_return(nil)
        item.should_receive(:initialize_workflow).with('versioningWF')
        item.stub(:save)
        post "/objects/#{item.pid}/versions"
        
        last_response.body.should == '2'
      end
    end
    
  end

end