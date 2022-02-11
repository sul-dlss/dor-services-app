# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteService do
  let(:service) { described_class.new(druid) }

  describe '#remove_active_workflows' do
    let(:druid) { 'druid:aa123bb4567' }
    let(:client) { instance_double(Dor::Workflow::Client, delete_all_workflows: nil) }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(client)
    end

    it 'calls the workflow client' do
      service.send(:remove_active_workflows)
      expect(client).to have_received(:delete_all_workflows).with(pid: druid)
    end
  end

  describe '#cleanup_stacks' do
    let(:fixture_dir) { '/tmp/cleanup-spec' }
    let(:stacks_dir) { File.join(fixture_dir, 'stacks') }
    let(:druid) { 'druid:cd456ef7890' }
    let(:stacks_druid) { DruidTools::StacksDruid.new(druid, Dor::Config.stacks.local_stacks_root) }

    before do
      allow(Dor::Config.stacks).to receive(:local_stacks_root).and_return(stacks_dir)
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
    let(:druid) { 'druid:cd456ef7890' }

    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

    before do
      allow(CocinaObjectStore).to receive(:destroy)
      AdministrativeTags.create(pid: druid, tags: ['test : tag'])
      Event.create!(druid: druid, event_type: 'version_close', data: { version: '4' })
      ObjectVersion.create(druid: druid, version: 4)
    end

    it 'deletes from datastore and Solr' do
      service.send(:delete_from_dor)
      expect(CocinaObjectStore).to have_received(:destroy).with(druid)
      expect(AdministrativeTags.for(pid: druid)).to be_empty
      expect(Event.exists?(druid: druid)).to be(false)
      expect(ObjectVersion.exists?(druid: druid)).to be(false)
    end
  end
end
