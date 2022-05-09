# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteService do
  let(:service) { described_class.new(cocina_object, event_factory) }

  let(:cocina_object) { build(:dro, id: druid, source_id: source_id) }

  let(:druid) { 'druid:bb408qn5061' }

  let(:source_id) { 'hydrus:object-63-sdr-client' }

  let(:event_factory) { class_double(EventFactory, create: nil) }

  let(:client) { instance_double(Dor::Workflow::Client, delete_all_workflows: nil) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
  end

  describe '#destroy' do
    before do
      allow(CocinaObjectStore).to receive(:destroy)
    end

    it 'creates an event' do
      service.destroy

      expect(event_factory).to have_received(:create).with(druid: druid, event_type: 'delete', data: { request: cocina_object.to_h, source_id: source_id })
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
      allow(CocinaObjectStore).to receive(:destroy)
      AdministrativeTags.create(identifier: druid, tags: ['test : tag'])
      Event.create!(druid: druid, event_type: 'version_close', data: { version: '4' })
      ObjectVersion.create(druid: druid, version: 4, tag: '4.0.0', description: 'Version 4.0.0')
    end

    it 'deletes from datastore and Solr' do
      service.send(:delete_from_dor)
      expect(CocinaObjectStore).to have_received(:destroy).with(druid)
      expect(AdministrativeTags.for(identifier: druid)).to be_empty
      expect(Event.exists?(druid: druid)).to be(false)
      expect(ObjectVersion.exists?(druid: druid)).to be(false)
    end
  end
end
