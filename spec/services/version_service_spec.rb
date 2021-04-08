# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionService do
  let(:druid) { 'druid:ab12cd3456' }

  let(:obj) do
    Dor::Item.new(pid: druid)
  end

  let(:vmd_ds) { obj.datastreams['versionMetadata'] }
  let(:ev_ds) { obj.datastreams['events'] }
  let(:event_factory) { class_double(EventFactory, create: true) }

  before do
    allow(obj).to receive(:pid).and_return(druid)

    allow(obj.inner_object).to receive(:repository).and_return(double('frepo').as_null_object)
  end

  describe '.open?' do
    let(:instance) { instance_double(described_class, open_for_versioning?: true) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates a new service instance and sends #open_for_versioning?' do
      described_class.open?(obj)
      expect(instance).to have_received(:open_for_versioning?).once
    end
  end

  describe '.in_accessioning?' do
    let(:instance) { instance_double(described_class, accessioning?: true) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates a new service instance and sends #accessioning?' do
      described_class.in_accessioning?(obj)
      expect(instance).to have_received(:accessioning?).once
    end
  end

  describe '.open' do
    subject(:open) { described_class.open(obj, event_factory: event_factory) }

    context 'when on the expected path' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
        allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
        allow(obj).to receive(:new_record?).and_return(false)
        allow(vmd_ds).to receive(:save)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        create_workflow_by_name: true,
                        lifecycle: true,
                        active_lifecycle: nil)
      end

      it 'creates the versionMetadata datastream and starts a workflow' do
        expect(Preservation::Client.objects).to receive(:current_version).and_return(1)
        expect(obj).to receive(:new_record?).and_return(false)
        expect(vmd_ds).to receive(:save)
        expect(vmd_ds.ng_xml.to_xml).to match(/Initial Version/)
        open
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1')
        expect(workflow_client).to have_received(:create_workflow_by_name).with(obj.pid, 'versioningWF', version: '2')
      end

      it 'includes options' do
        options = { significance: 'real_major', description: 'same as it ever was', opening_user_name: 'sunetid' }
        cur_vers = '2'
        allow(vmd_ds).to receive(:current_version).and_return(cur_vers)
        allow(obj).to receive(:save!)

        expect(ev_ds).to receive(:add_event).with('open', options[:opening_user_name], "Version #{cur_vers} opened")
        expect(vmd_ds).to receive(:update_current_version).with(description: options[:description], significance: options[:significance].to_sym)
        expect(obj).to receive(:save!)

        described_class.open(obj, options, event_factory: event_factory)

        expect(event_factory).to have_received(:create).with(data: { version: '2', who: 'sunetid' },
                                                             druid: 'druid:ab12cd3456',
                                                             event_type: 'version_open')
      end

      it "doesn't include options" do
        expect(ev_ds).not_to receive(:add_event)
        expect(vmd_ds).not_to receive(:update_current_version)
        expect(obj).not_to receive(:save!)

        open
      end
    end

    context 'when a new version cannot be opened' do
      let(:instance) { described_class.new obj }

      before do
        allow(instance).to receive(:try_to_get_current_version).and_raise(Dor::Exception, 'Object net yet accessioned')
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(Dor::Exception, 'Object net yet accessioned')
      end
    end

    context "when Preservation's current version is greater than the current version" do
      before do
        allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client)
      end

      it 'raises an exception' do
        expect(workflow_client).to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned').and_return(true)
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(nil)
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1').and_return(nil)
        expect(Preservation::Client.objects).to receive(:current_version).and_return(3)
        expect { open }.to raise_error(Dor::Exception, 'Cannot sync to a version greater than current: 1, requested 3')
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        lifecycle: true,
                        active_lifecycle: nil)
      end

      it 'raises an exception' do
        errmsg = "Preservation (SDR) is not yet answering queries about this object. When an object has just been transferred, Preservation isn't immediately ready to answer queries."
        expect { open }.to raise_error(Dor::Exception, errmsg)
      end
    end
  end

  describe '.can_open?' do
    subject(:can_open?) { described_class.can_open?(obj) }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      lifecycle: true,
                      active_lifecycle: nil)
    end

    context 'when a new version can be opened' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
      end

      it 'returns true' do
        expect(can_open?).to be true
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1')
      end
    end

    context 'when the object has not been accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).with(druid: druid, milestone_name: 'accessioned').and_return(false)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
      end
    end

    context 'when the object has already been opened' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(Time.new)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
      end
    end

    context 'when the object is still being accessioned' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1').and_return(Time.new)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1')
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      it 'returns false' do
        expect(can_open?).to be false
      end
    end
  end

  describe '.close' do
    subject(:close) { described_class.close(obj, event_factory: event_factory) }

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client)
    end

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    context 'when significance, description and user_name are passed in' do
      subject(:close) do
        described_class.close(obj,
                              {
                                description: 'closing text',
                                significance: 'major',
                                user_name: 'jcoyne'
                              },
                              event_factory: event_factory)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client, close_version: true)
      end

      before do
        allow(vmd_ds).to receive(:pid).and_return('druid:ab123cd4567')
        # stub out calls for open_for_versioning?
        allow(workflow_client).to receive(:active_lifecycle).and_return(true, false)
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')

        allow(vmd_ds).to receive(:save)
        allow(ev_ds).to receive(:add_event)
        allow(obj).to receive(:save!)

        vmd_ds.increment_version
      end

      it 'sets tag, description and an event' do
        close
        expect(vmd_ds).to have_received(:save)
        expect(event_factory).to have_received(:create).with(data: { version: '2', who: 'jcoyne' },
                                                             druid: 'druid:ab12cd3456',
                                                             event_type: 'version_close')

        expect(workflow_client).to have_received(:close_version)
          .with(druid: druid, version: '2', create_accession_wf: true)

        expect(ev_ds).to have_received(:add_event).with('close', 'jcoyne', 'Version 2 closed')
        expect(obj).to have_received(:save!)

        expect(vmd_ds.to_xml).to be_equivalent_to <<~XML
          <versionMetadata objectId="druid:ab123cd4567">
            <version versionId="1" tag="1.0.0">
              <description>Initial Version</description>
            </version>
            <version versionId="2" tag="2.0.0">
              <description>closing text</description>
            </version>
          </versionMetadata>
        XML
      end
    end

    context 'when start_accession is false' do
      subject(:close) do
        described_class.close(obj,
                              {
                                description: 'closing text',
                                significance: 'major',
                                user_name: 'jcoyne',
                                start_accession: false
                              },
                              event_factory: event_factory)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client, close_version: true)
      end

      before do
        allow(vmd_ds).to receive(:pid).and_return('druid:ab123cd4567')
        # stub out calls for open_for_versioning?
        allow(workflow_client).to receive(:active_lifecycle).and_return(true, false)
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
        allow(vmd_ds).to receive(:save)
        allow(ev_ds).to receive(:add_event)
        allow(obj).to receive(:save!)
        vmd_ds.increment_version
      end

      it 'passes the correct value of create_accession_wf' do
        close
        expect(workflow_client).to have_received(:close_version)
          .with(druid: druid, version: '2', create_accession_wf: false)
      end
    end

    context 'when the object has not been opened for versioning' do
      it 'raises an exception' do
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(nil)
        expect { close }.to raise_error(Dor::Exception, 'Trying to close version on druid:ab12cd3456 which is not opened for versioning')
      end
    end

    context 'when the object has an active accesssionWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
      end

      it 'raises an exception' do
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(Time.new)
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1').and_return(true)
        expect { close }.to raise_error(Dor::Exception, 'accessionWF already created for versioned object druid:ab12cd3456')
      end
    end

    context 'when the object has an active assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('waiting')
      end

      it 'raises an exception' do
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(Time.new)
        expect { close }.to raise_error(Dor::Exception, 'Trying to close version on druid:ab12cd3456 which has active assemblyWF')
        expect(workflow_client).to have_received(:workflow_status).with(hash_including(workflow: 'assemblyWF'))
      end
    end

    context 'when the object has no assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return(nil)
        allow(workflow_client).to receive(:close_version)
        allow(obj).to receive(:save!)
      end

      it 'creates the accessioningWF' do
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1').and_return(Time.new)
        expect(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1').and_return(false)
        close
        expect(workflow_client).to have_received(:workflow_status).with(hash_including(workflow: 'assemblyWF'))
        expect(workflow_client).to have_received(:close_version).with(druid: druid, version: '1', create_accession_wf: true)
      end
    end

    context 'when the latest version does not have a tag and a description' do
      it 'raises an exception' do
        vmd_ds.increment_version
        expect { close }.to raise_error(Dor::Exception, 'latest version in versionMetadata for druid:ab12cd3456 requires tag and description before it can be closed')
      end
    end
  end
end
