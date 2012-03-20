require 'spec_helper'

class AssembleableItem
  include Dor::Assembleable
  attr_accessor :pid
end

describe Dor::DorServicesApi do
  def app
    @app ||= Dor::DorServicesApi
  end
  
  before(:each) do
    ActiveFedora.stub!(:fedora).and_return(stub('frepo').as_null_object)
    FileUtils.rm_rf Dir.glob('/tmp/dor/*')
    @item = AssembleableItem.new
    @item.pid = 'druid:aa123bb4567'
    Dor::Item.stub!(:load_instance).and_return(@item)
  end
  
  after(:all) do
    FileUtils.rm_rf Dir.glob('/tmp/dor/*')
  end
  
  describe "initialize_workspace" do
    
    it "creates a druid tree in the dor workspace for the passed in druid" do
      post "/v1/objects/#{@item.pid}/initialize_workspace"
      File.should be_directory('/tmp/dor/aa/123/bb/4567')
    end
    
    it "creates a link in the dor workspace to the path passed in as source" do
      post "/v1/objects/#{@item.pid}/initialize_workspace", :source => '/tmp/stage/obj1'
      File.should be_symlink('/tmp/dor/aa/123/bb/4567')
    end
    
    context "error handling" do
      before(:each) do
        druid = Druid.new(@item.pid)
        druid.mkdir('/tmp/dor')
      end
      
      it "returns a 409 Conflict http status code when the link/directory already exists" do
        post "/v1/objects/#{@item.pid}/initialize_workspace"
        
        last_response.status.should == 409
        last_response.body.should =~ /The directory already exists/
      end
      
      it "returns a 409 Conflict http status code when the workspace already exists with different content" do
        post "/v1/objects/#{@item.pid}/initialize_workspace", :source => '/some/path'
        
        last_response.status.should == 409
        last_response.body.should =~ /Unable to create link, directory already exists/
      end
    end
    
  end

  describe "accession" do
    it "initiates accessionWF via obj.initiate_apo_workflow" do
      @item.should_receive(:initiate_apo_workflow).with('accessionWF')
      
      post "/v1/objects/#{@item.pid}/accession"
    end
  end

  describe "object registration" do
    context "error handling" do
      it "returns a 409 error with location header when an object already exists" do
        Dor::RegistrationService.stub!(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))

        post "/v1/objects", :some => 'param'
        last_response.status.should == 409
        last_response.headers['location'].should == 'http://dor-dev.stanford.edu/fedora/objects/druid:existing123obj'
      end

      it "logs all unhandled exceptions" do
        Dor::RegistrationService.stub!(:register_object).and_raise(Exception.new("Testing Exception Logging"))
        LyberCore::Log.should_receive(:exception)

        post "/v1/objects", :some => 'param'
      end
    end
  end
end