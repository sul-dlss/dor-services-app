require 'rails_helper'

RSpec.describe VersionsController do
  let(:item) { AssembleableVersionableItem.new.tap { |x| x.pid = 'druid:aa123bb4567' } }

  before do
    allow(Dor).to receive(:find).and_return(item)
  end

  before do
    login
  end

  describe '/versions/current' do
    it 'returns the latest version for an object' do
      get :current, params: { object_id: item.pid }
      expect(response.body).to eq('1')
    end
  end

  describe '/versions/current/close' do
    it 'closes the current version when posted to' do
      expect(Dor::VersionService).to receive(:close)
      post :close_current, params: { object_id: item.pid }
      expect(response.body).to match(/version 1 closed/)
    end

    it 'forwards optional params to the Dor::VersionService#close method' do
      expect(Dor::VersionService).to receive(:close).with(item, description: 'some text', significance: :major)
      post :close_current, params: { object_id: item.pid }, body: %( {"description": "some text", "significance": "major"} )
      expect(response.body).to match(/version 1 closed/)
    end
  end

  describe '/versions' do
    it 'opens a new object version when posted to' do
      expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', item.pid, 'accessioned').and_return(true)
      expect(Dor::Config.workflow.client).to receive(:get_active_lifecycle).with('dor', item.pid, 'submitted').and_return(nil)
      expect(Dor::Config.workflow.client).to receive(:get_active_lifecycle).with('dor', item.pid, 'opened').and_return(nil)
      expect(Sdr::Client).to receive(:current_version).and_return(1)
      # Do not test workflow side effects in dor-services-app; that is dor-services' responsibility
      allow(Dor::CreateWorkflowService).to receive(:create_workflow)
      post :create, params: { object_id: item.pid }
      expect(response.body).to eq('2')
    end
  end
end
