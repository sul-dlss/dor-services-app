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

  let(:item) { AssembleableVersionableItem.new }

  before(:each) do
    allow(ActiveFedora).to receive(:fedora).and_return(double('frepo').as_null_object)
    clean_workspace
    item.pid = 'druid:aa123bb4567'
    allow(Dor::Item).to receive(:find).and_return(item)
    allow(item).to receive(:remove_druid_prefix).and_return('aa123bb4567')
  end

  after(:all) { clean_workspace }

  it 'handles simple ping requests to /about' do
    get '/v1/about'
    expect(last_response).to be_ok
    expect(last_response.body).to match(/version: \d\..*$/)
  end

  describe 'sdr' do
    before(:each) { login }

    describe 'current_version' do
      let(:mock_response) { '<currentVersion>1</currentVersion>' }

      it 'retrieves the current version from SDR' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/current_version", body: mock_response, content_type: 'application/xml')

        get "/v1/sdr/objects/#{item.pid}/current_version"

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq mock_response
        expect(last_response.content_type).to eq 'application/xml'
      end

      it 'passes through error codes' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/current_version", status: 404, body: '')

        get "/v1/sdr/objects/#{item.pid}/current_version"

        expect(last_response.status).to eq 404
      end
    end

    describe 'preserved content' do
      let(:item_version) { 3 }
      let(:content_file_name_txt) { 'content_file.txt' }
      let(:content_type_txt) { 'application/text' }
      let(:mock_response_txt) { 'some file content' }

      it 'passes through errors' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/no_such_file?version=2", status: 404)
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/unexpected_error?version=2", status: 500)

        get "/v1/sdr/objects/#{item.pid}/content/no_such_file?version=2"
        expect(last_response.status).to eq 404

        get "/v1/sdr/objects/#{item.pid}/content/unexpected_error?version=2"
        expect(last_response.status).to eq 500
      end

      context 'URI encoding' do
        let(:filename_with_spaces) { 'filename with spaces' }
        let(:uri_encoded_filename) { URI.encode(filename_with_spaces) }

        it 'handles file names with characters that need URI encoding' do
          FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/#{uri_encoded_filename}?version=#{item_version}", body: mock_response_txt, content_type: content_type_txt)

          get "/v1/sdr/objects/#{item.pid}/content/#{uri_encoded_filename}?version=#{item_version}"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq mock_response_txt
          expect(last_response.content_type).to eq content_type_txt
        end
      end

      context 'text file type' do
        it 'retrieves the content for a version of a text file from SDR' do
          FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/#{content_file_name_txt}?version=#{item_version}", body: mock_response_txt, content_type: content_type_txt)

          get "/v1/sdr/objects/#{item.pid}/content/#{content_file_name_txt}?version=#{item_version}"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq mock_response_txt
          expect(last_response.content_type).to eq content_type_txt
        end
      end

      # test with a small (but not tiny) chunk of binary content, fixture is just over 3 MB
      context 'image file type' do
        let(:img_fixture_filename) { 'spec/fixtures/simple_image_fixture.jpg' }
        let(:content_file_name_jpg) { 'old_img.jpg' }
        let(:content_type_jpg) { 'image/jpg' }
        let(:mock_response_jpg) { URI.encode_www_form_component(File.binread(img_fixture_filename)) }

        it 'retrieves the content for a version of a text file from SDR' do
          FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/#{content_file_name_jpg}?version=#{item_version}", body: mock_response_jpg, content_type: content_type_jpg)

          get "/v1/sdr/objects/#{item.pid}/content/#{content_file_name_jpg}?version=#{item_version}"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq mock_response_jpg
          expect(last_response.content_type).to eq content_type_jpg
        end
      end
    end

    describe 'cm-inv-diff' do
      let(:mock_response) { 'cm-inv-diff' }
      context 'with an invalid subset value' do
        it 'fails as a bad request' do
          post "/v1/sdr/objects/#{item.pid}/cm-inv-diff?subset=wrong"

          expect(last_response.status).to eq 400
        end
      end

      context 'with an explicit version' do
        it 'passes the version to SDR' do
          FakeWeb.register_uri(:post, "#{Dor::Config.sdr.url}/objects/#{item.pid}/cm-inv-diff?subset=all&version=5", body: mock_response, content_type: 'application/xml')

          post "/v1/sdr/objects/#{item.pid}/cm-inv-diff?subset=all&version=5"
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq mock_response
          expect(last_response.content_type).to eq 'application/xml'
        end
      end

      it 'retrieves the diff from SDR' do
        FakeWeb.register_uri(:post, "#{Dor::Config.sdr.url}/objects/#{item.pid}/cm-inv-diff?subset=all", body: mock_response, content_type: 'application/xml')

        post "/v1/sdr/objects/#{item.pid}/cm-inv-diff?subset=all"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq mock_response
        expect(last_response.content_type).to eq 'application/xml'
      end
    end

    describe 'signatureCatalog' do
      it 'retrieves the catalog from SDR' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/manifest/signatureCatalog.xml", body: '<catalog />', content_type: 'application/xml')

        get "/v1/sdr/objects/#{item.pid}/manifest/signatureCatalog.xml"

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq '<catalog />'
        expect(last_response.content_type).to eq 'application/xml'
      end

      it 'passes through errors' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/manifest/signatureCatalog.xml", status: 428)

        get "/v1/sdr/objects/#{item.pid}/manifest/signatureCatalog.xml"

        expect(last_response.status).to eq 428
      end
    end

    describe 'metadata services' do
      it 'retrieves the datastream from SDR' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/metadata/whatever", body: 'content', content_type: 'application/xml')

        get "/v1/sdr/objects/#{item.pid}/metadata/whatever"

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq 'content'
        expect(last_response.content_type).to eq 'application/xml'
      end

      it 'passes through errors' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/metadata/whatever", status: 428)

        get "/v1/sdr/objects/#{item.pid}/metadata/whatever"

        expect(last_response.status).to eq 428
      end
    end
  end

  describe 'initialize_workspace' do
    before(:each) { login }

    it 'creates a druid tree in the dor workspace for the passed in druid' do
      post "/v1/objects/#{item.pid}/initialize_workspace"
      expect(File).to be_directory(TEST_WORKSPACE + '/aa/123/bb/4567')
    end

    it 'creates a link in the dor workspace to the path passed in as source' do
      post "/v1/objects/#{item.pid}/initialize_workspace", :source => '/some/path'
      expect(File).to be_symlink(TEST_WORKSPACE + '/aa/123/bb/4567/aa123bb4567')
    end

    context 'error handling' do
      before(:each) do
        druid = DruidTools::Druid.new(item.pid, TEST_WORKSPACE)
        druid.mkdir
      end

      it 'returns a 409 Conflict http status code when the link/directory already exists' do
        post "/v1/objects/#{item.pid}/initialize_workspace"
        expect(last_response.status).to eq(409)
        expect(last_response.body).to match(/The directory already exists/)
      end

      it 'returns a 409 Conflict http status code when the workspace already exists with different content' do
        post "/v1/objects/#{item.pid}/initialize_workspace", :source => '/some/path'
        expect(last_response.status).to eq(409)
        expect(last_response.body).to match(/Unable to create link, directory already exists/)
      end
    end
  end

  describe '/publish' do
    before(:each) { login }

    it 'calls publish metadata' do
      expect(item).to receive(:publish_metadata)
      post "/v1/objects/#{item.pid}/publish"
      expect(last_response.status).to eq(201)
    end
  end

  describe '/release_tags' do
    before(:each) { login }

    it 'adds a release tag when posted to with false' do
      expect(item).to receive(:add_release_node).with(false, :to => 'searchworks', :who => 'carrickr', :what => 'self', :release => false)
      expect(item).to receive(:save)
      post "/v1/objects/#{item.pid}/release_tags", %( {"to":"searchworks","who":"carrickr","what":"self","release":false} )
      expect(last_response.status).to eq(201)
    end

    it 'adds a release tag when posted to with true' do
      expect(item).to receive(:add_release_node).with(true, :to => 'searchworks', :who => 'carrickr', :what => 'self', :release => true)
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

  describe '/update_marc_record' do
    before(:each) { login }

    it 'updates a marc record' do
      # TODO: add some more expectations
      post "/v1/objects/#{item.pid}/update_marc_record"
      expect(last_response.status).to eq(201)
    end
  end

  describe '/notify_goobi' do
    before(:each) { login }

    it 'notifies goobi of a new registration by making a web service call' do
      Dor::Config.goobi.max_tries = 1
      FakeWeb.register_uri(:post, Dor::Config.goobi.url, body: '', content_type: 'text/xml')
      fake_response = "<stanfordCreationRequest><objectId>#{item.pid}</objectId></stanfordCreationRequest>"
      allow_any_instance_of(Dor::Goobi).to receive(:xml_request).and_return(fake_response)
      expect_any_instance_of(Dor::Goobi).to receive(:register).once
      post "/v1/objects/#{item.pid}/notify_goobi"
      expect(last_response.status).to eq(201)
    end
  end

  describe 'apo-workflow intialization' do
    before(:each) { login }

    it 'initiates accessionWF via obj.initiate_apo_workflow' do
      expect(item).to receive(:initiate_apo_workflow).with('assemblyWF')
      post "/v1/objects/#{item.pid}/apo_workflows/assemblyWF"
    end

    it "handles workflow names without 'WF' appended to the end" do
      expect(item).to receive(:initiate_apo_workflow).with('accessionWF')
      post "/v1/objects/#{item.pid}/apo_workflows/accession"
    end
  end

  describe 'object registration' do
    before(:each) { login }

    context 'error handling' do
      it 'returns a 409 error with location header when an object already exists' do
        allow(Dor::RegistrationService).to receive(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))
        post '/v1/objects', :some => 'param'
        expect(last_response.status).to eq(409)
        expect(last_response.headers['location']).to match(/\/fedora\/objects\/druid:existing123obj/)
      end

      it 'logs all unhandled exceptions' do
        allow(Dor::RegistrationService).to receive(:register_object).and_raise(StandardError.new('Testing Exception Logging'))
        expect(LyberCore::Log).to receive(:exception)
        post '/v1/objects', :some => 'param'
        expect(last_response.status).to eq(500)
      end
    end
  end

  describe 'versioning' do
    before(:each) { login }

    describe '/versions/current' do
      it 'returns the latest version for an object' do
        get "/v1/objects/#{item.pid}/versions/current"
        expect(last_response.body).to eq('1')
      end
    end

    describe '/versions/current/close' do
      it 'closes the current version when posted to' do
        expect(item).to receive(:close_version)
        post "/v1/objects/#{item.pid}/versions/current/close"
        expect(last_response.body).to match(/version 1 closed/)
      end

      it 'forwards optional params to the Dor::Item#close_version method' do
        expect(item).to receive(:close_version).with(:description => 'some text', :significance => :major)
        post "/v1/objects/#{item.pid}/versions/current/close", %( {"description": "some text", "significance": "major"} )
        expect(last_response.body).to match(/version 1 closed/)
      end
    end

    describe '/versions' do
      it 'opens a new object version when posted to' do
        expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', item.pid, 'accessioned').and_return(true)
        expect(Dor::Config.workflow.client).to receive(:get_active_lifecycle).with('dor', item.pid, 'submitted').and_return(nil)
        expect(Dor::Config.workflow.client).to receive(:get_active_lifecycle).with('dor', item.pid, 'opened').and_return(nil)
        expect(Sdr::Client).to receive(:current_version).and_return(1)
        expect(item).to receive(:create_workflow).with('versioningWF')
        allow(item).to receive(:save)
        post "/v1/objects/#{item.pid}/versions"
        expect(last_response.body).to eq('2')
      end
    end
  end

  describe 'workflow archiving' do
    before(:each) { login }

    it 'POSTing to /objects/{druid}/workflows/{wfname}/archive archives a workflow for a given druid and repository' do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '1')
      post "/v1/objects/#{item.pid}/workflows/accessionWF/archive"
      expect(last_response.body).to eq('accessionWF version 1 archived')
    end

    it 'POSTing to /objects/{druid}/workflows/{wfname}/archive/{ver_num} archives a workflow with a specic version' do
      allow_any_instance_of(Dor::WorkflowArchiver).to receive(:connect_to_db)
      expect_any_instance_of(Dor::WorkflowArchiver).to receive(:archive_one_datastream).with('dor', item.pid, 'accessionWF', '3')
      post "/v1/objects/#{item.pid}/workflows/accessionWF/archive/3"
      expect(last_response.body).to eq('accessionWF version 3 archived')
    end

    it 'checks if all rows are complete before archiving' do
      skip 'Maybe check should be in the gem'
    end
  end

  describe 'workflow definitions' do
    before(:each) { login }

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
