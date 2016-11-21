require 'rails_helper'

RSpec.describe SdrController do
  let(:item) { AssembleableVersionableItem.new.tap { |x| x.pid = 'druid:aa123bb4567' } }

  before(:each) do
    allow(Dor).to receive(:find).and_return(item)
  end

  before do
    login
  end

  describe 'current_version' do
    let(:mock_response) { '<currentVersion>1</currentVersion>' }

    it 'retrieves the current version from SDR' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/current_version", body: mock_response, content_type: 'application/xml')

      get :current_version, params: { druid: item.pid }

      expect(response.status).to eq 200
      expect(response.body).to eq mock_response
      expect(response.content_type).to eq 'application/xml'
    end

    it 'passes through error codes' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/current_version", status: 404, body: '')

      get :current_version, params: { druid: item.pid }

      expect(response.status).to eq 404
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

      get :file_content, params: { druid: item.pid, filename: 'no_such_file', version: 2 }
      expect(response.status).to eq 404

      get :file_content, params: { druid: item.pid, filename: 'unexpected_error', version: 2 }
      expect(response.status).to eq 500
    end

    context 'URI encoding' do
      let(:filename_with_spaces) { 'filename with spaces' }
      let(:uri_encoded_filename) { URI.encode(filename_with_spaces) }

      it 'handles file names with characters that need URI encoding' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/#{uri_encoded_filename}?version=#{item_version}", body: mock_response_txt, content_type: content_type_txt)
        
        get :file_content, params: { druid: item.pid, filename: filename_with_spaces, version: item_version }

        expect(response.status).to eq 200
        expect(response.body).to eq mock_response_txt
        expect(response.content_type).to eq content_type_txt
      end
    end

    context 'text file type' do
      it 'retrieves the content for a version of a text file from SDR' do
        FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/content/#{content_file_name_txt}?version=#{item_version}", body: mock_response_txt, content_type: content_type_txt)
        
        get :file_content, params: { druid: item.pid, filename: content_file_name_txt, version: item_version }

        expect(response.status).to eq 200
        expect(response.body).to eq mock_response_txt
        expect(response.content_type).to eq content_type_txt
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
        
        get :file_content, params: { druid: item.pid, filename: content_file_name_jpg, version: item_version }

        expect(response.status).to eq 200
        expect(response.body).to eq mock_response_jpg
        expect(response.content_type).to eq content_type_jpg
      end
    end
  end

  describe 'cm-inv-diff' do
    let(:mock_response) { 'cm-inv-diff' }
    context 'with an invalid subset value' do
      it 'fails as a bad request' do
        post :cm_inv_diff, params: { druid: item.pid, subset: 'wrong' }

        expect(response.status).to eq 400
      end
    end

    context 'with an explicit version' do
      it 'passes the version to SDR' do
        FakeWeb.register_uri(:post, "#{Dor::Config.sdr.url}/objects/#{item.pid}/cm-inv-diff?subset=all&version=5", body: mock_response, content_type: 'application/xml')
        
        post :cm_inv_diff, params: { druid: item.pid, subset: 'all', version: 5 }
        expect(response.status).to eq 200
        expect(response.body).to eq mock_response
        expect(response.content_type).to eq 'application/xml'
      end
    end

    it 'retrieves the diff from SDR' do
      FakeWeb.register_uri(:post, "#{Dor::Config.sdr.url}/objects/#{item.pid}/cm-inv-diff?subset=all", body: mock_response, content_type: 'application/xml')
      
      post :cm_inv_diff, params: { druid: item.pid, subset: 'all' }
      expect(response.status).to eq 200
      expect(response.body).to eq mock_response
      expect(response.content_type).to eq 'application/xml'
    end
  end

  describe 'signatureCatalog' do
    it 'retrieves the catalog from SDR' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/manifest/signatureCatalog.xml", body: '<catalog />', content_type: 'application/xml')

      get :ds_manifest, params: { druid: item.pid, dsname: 'signatureCatalog.xml' }

      expect(response.status).to eq 200
      expect(response.body).to eq '<catalog />'
      expect(response.content_type).to eq 'application/xml'
    end

    it 'passes through errors' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/manifest/signatureCatalog.xml", status: 428)

      get :ds_manifest, params: { druid: item.pid, dsname: 'signatureCatalog.xml' }

      expect(response.status).to eq 428
    end
  end

  describe 'metadata services' do
    it 'retrieves the datastream from SDR' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/metadata/whatever", body: 'content', content_type: 'application/xml')
      
      get :ds_metadata, params: { druid: item.pid, dsname: 'whatever' }

      expect(response.status).to eq 200
      expect(response.body).to eq 'content'
      expect(response.content_type).to eq 'application/xml'
    end

    it 'passes through errors' do
      FakeWeb.register_uri(:get, "#{Dor::Config.sdr.url}/objects/#{item.pid}/metadata/whatever", status: 428)

      get :ds_metadata, params: { druid: item.pid, dsname: 'whatever' }

      expect(response.status).to eq 428
    end
  end
end
