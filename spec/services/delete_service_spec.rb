# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteService do
  let(:service) { described_class.new(cocina_object, user_name) }
  let(:cocina_object) { build(:dro, id: druid, source_id:) }
  let(:druid) { 'druid:bb408qn5061' }
  let(:source_id) { 'hydrus:object-63-sdr-client' }
  let(:user_name) { 'some_person' }
  let(:client) { instance_double(Dor::Workflow::Client, delete_all_workflows: nil) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
    allow(EventFactory).to receive(:create).and_return(nil)
  end

  describe '#destroy' do
    subject(:destroy) { described_class.destroy(cocina_object, user_name:) }

    before do
      create(:repository_object, external_identifier: druid)
      allow(CocinaObjectStore).to receive(:destroy)
      allow(Indexer).to receive(:delete)
    end

    it 'destroys the object' do
      expect { destroy }
        .to change(RepositoryObject, :count).by(-1)
        .and change(RepositoryObjectVersion, :count).by(-1)
      expect(EventFactory).to have_received(:create).with(druid:, event_type: 'delete', data: { request: cocina_object.to_h, source_id:, user_name: })
      expect(Indexer).to have_received(:delete)
    end
  end

  describe '#remove_active_workflows' do
    it 'calls the workflow client' do
      service.send(:remove_active_workflows)
      expect(client).to have_received(:delete_all_workflows).with(pid: druid)
    end
  end

  describe '#cleanup_stacks' do
    let(:fixture_dir) { '/tmp/cleanup-spec' }
    let(:stacks_dir) { File.join(fixture_dir, 'stacks') }
    let(:stacks_druid) { DruidTools::StacksDruid.new(druid, Settings.stacks.local_stacks_root) }

    before do
      allow(Settings.stacks).to receive(:local_stacks_root).and_return(stacks_dir)
      FileUtils.mkdir fixture_dir
      FileUtils.mkdir stacks_dir

      stacks_druid.mkdir

      File.write(File.join(stacks_druid.path, 'tempfile'), 'junk')
    end

    after do
      FileUtils.rm_rf fixture_dir
    end

    it 'prunes the item from the local stacks root' do
      expect { service.send(:cleanup_stacks) }.to change { File.exist?(stacks_druid.path) }
        .from(true).to(false)
    end
  end

  describe '#delete_from_dor' do
    before do
      create(:repository_object, external_identifier: druid)
      AdministrativeTags.create(identifier: druid, tags: ['test : tag'])
      Event.create!(druid:, event_type: 'version_close', data: { version: '4' })
      ReleaseTag.create(druid:, who: 'bergeraj', what: 'self', released_to: 'Searchworks', release: true)
      allow(Indexer).to receive(:delete)
    end

    it 'deletes from datastore and Solr' do
      expect { service.send(:delete_from_dor) }
        .to change(RepositoryObject, :count).by(-1)
        .and change(RepositoryObjectVersion, :count).by(-1)
      expect(AdministrativeTags.for(identifier: druid)).to be_empty
      expect(Event.exists?(druid:)).to be(false)
      expect(ReleaseTag.exists?(druid:)).to be(false)
      expect(Indexer).to have_received(:delete).with(druid:)
    end
  end
end
