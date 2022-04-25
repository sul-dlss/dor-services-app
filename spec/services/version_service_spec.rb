# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionService do
  let(:druid) { 'druid:xz456jk0987' }

  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: version, new: nil) }

  let(:version) { 1 }

  let(:event_factory) { class_double(EventFactory, create: true) }

  describe '.open?' do
    let(:instance) { instance_double(described_class, open_for_versioning?: true) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates a new service instance and sends #open_for_versioning?' do
      described_class.open?(cocina_object)
      expect(instance).to have_received(:open_for_versioning?).once
    end
  end

  describe '.in_accessioning?' do
    let(:instance) { instance_double(described_class, accessioning?: true) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates a new service instance and sends #accessioning?' do
      described_class.in_accessioning?(cocina_object)
      expect(instance).to have_received(:accessioning?).once
    end
  end

  describe '.open' do
    subject(:open) do
      described_class.open(cocina_object,
                           event_factory: event_factory,
                           description: description,
                           significance: significance)
    end

    let(:description) { 'covid 19 version' }
    let(:significance) { 'minor' }

    before do
      allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(CocinaObjectStore).to receive(:save)
      allow(VersionMigrationService).to receive(:find_and_migrate)
      ObjectVersion.create(druid: druid, version: 1, tag: '1.0.0')
      allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      create_workflow_by_name: true,
                      lifecycle: true,
                      active_lifecycle: nil)
    end

    context 'when on the expected path' do
      it 'creates an object version and starts a workflow' do
        open
        expect(cocina_object).to have_received(:new).with(version: 2)
        expect(ObjectVersion.current_version(druid).version).to eq(2)
        expect(CocinaObjectStore).to have_received(:save)
        expect(VersionMigrationService).to have_received(:find_and_migrate).with(druid)
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1')
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'versioningWF', version: '2')

        expect(event_factory).to have_received(:create).with(data: { version: '2', who: nil },
                                                             druid: druid,
                                                             event_type: 'version_open')
      end

      it 'includes information from params' do
        described_class.open(cocina_object,
                             significance: 'major',
                             description: 'same as it ever was',
                             opening_user_name: 'sunetid',
                             event_factory: event_factory)

        current_version = ObjectVersion.current_version(druid)
        expect(current_version.version).to eq(2)
        expect(current_version.tag).to eq('2.0.0')
        expect(current_version.description).to eq('same as it ever was')

        expect(event_factory).to have_received(:create).with(data: { version: '2', who: 'sunetid' },
                                                             druid: druid,
                                                             event_type: 'version_open')
      end
    end

    context 'when skipping the preservation catalog sync' do
      before do
        allow(Settings.version_service).to receive(:sync_with_preservation).and_return false
        allow(ObjectVersion).to receive(:sync_then_increment_version)
      end

      it 'creates an object version and starts a workflow' do
        open
        expect(cocina_object).to have_received(:new).with(version: 2)
        expect(ObjectVersion.current_version(druid).version).to eq(2)
        expect(ObjectVersion).not_to have_received(:sync_then_increment_version)
        expect(CocinaObjectStore).to have_received(:save)
        expect(VersionMigrationService).to have_received(:find_and_migrate).with(druid)
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
        expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '1')
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'versioningWF', version: '2')

        expect(event_factory).to have_received(:create).with(data: { version: '2', who: nil },
                                                             druid: druid,
                                                             event_type: 'version_open')
      end
    end

    context 'when a new version cannot be opened' do
      let(:instance) { described_class.new(cocina_object) }

      before do
        allow(instance).to receive(:ensure_openable!).and_raise(Dor::Exception, 'Object net yet accessioned')
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(Dor::Exception, 'Object net yet accessioned')
      end
    end

    context "when Preservation's current version is greater than the current version" do
      it 'raises an exception' do
        expect(Preservation::Client.objects).to receive(:current_version).and_return(3)
        expect { open }.to raise_error(Dor::Exception, 'Cannot sync to a version greater than current: 1, requested 3')
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises an exception' do
        errmsg = "Preservation (SDR) is not yet answering queries about this object. When an object has just been transferred, Preservation isn't immediately ready to answer queries."
        expect { open }.to raise_error(Dor::Exception, errmsg)
      end
    end

    context 'when required arguments are missing' do
      let(:description) { nil }

      it 'raises ArgumentError' do
        expect { open }.to raise_error(ArgumentError, 'description and significance are required to open a new version')
      end
    end
  end

  describe '.can_open?' do
    subject(:can_open?) { described_class.can_open?(cocina_object) }

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

      context 'when assume_accessioned is true' do
        before do
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
        end

        it 'returns true' do
          expect(described_class.can_open?(cocina_object, assume_accessioned: true)).to be true
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '1')
        end
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
    subject(:close) do
      described_class.close(cocina_object,
                            description: 'closing text',
                            significance: 'major',
                            user_name: 'jcoyne',
                            event_factory: event_factory)
    end

    let(:version) { 2 }

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client)
    end

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(VersionMigrationService).to receive(:find_and_migrate)
      ObjectVersion.create(druid: druid, version: 1, tag: '1.0.0')
      ObjectVersion.create(druid: druid, version: 2)
    end

    context 'when significance, description and user_name are passed in' do
      before do
        # stub out calls for open_for_versioning?
        allow(workflow_client).to receive(:active_lifecycle).and_return(true, false)
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
        allow(workflow_client).to receive(:close_version)
      end

      it 'sets tag, description and an event' do
        close
        object_version = ObjectVersion.find_by(druid: druid, version: 2)
        expect(object_version.tag).to eq('1.0.0')
        expect(object_version.description).to eq('closing text')
        expect(event_factory).to have_received(:create).with(data: { version: '2', who: 'jcoyne' },
                                                             druid: druid,
                                                             event_type: 'version_close')

        expect(workflow_client).to have_received(:close_version)
          .with(druid: druid, version: '2', create_accession_wf: true)
      end
    end

    context 'when start_accession is false' do
      subject(:close) do
        described_class.close(cocina_object,
                              description: 'closing text',
                              significance: 'major',
                              user_name: 'jcoyne',
                              start_accession: false,
                              event_factory: event_factory)
      end

      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(true, false)
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
        allow(workflow_client).to receive(:close_version)
      end

      it 'passes the correct value of create_accession_wf' do
        close
        expect(workflow_client).to have_received(:close_version)
          .with(druid: druid, version: '2', create_accession_wf: false)
      end
    end

    context 'when the object has not been opened for versioning' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '2').and_return(nil)
      end

      it 'raises an exception' do
        expect { close }.to raise_error(Dor::Exception, "Trying to close version 2 on #{druid} which is not opened for versioning")
      end
    end

    context 'when the object has an active accesssionWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '2').and_return(Time.new)
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '2').and_return(true)
      end

      it 'raises an exception' do
        expect { close }.to raise_error(Dor::Exception, "accessionWF already created for versioned object #{druid}")
      end
    end

    context 'when the object has an active assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('waiting')
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '2').and_return(Time.new)
      end

      it 'raises an exception' do
        expect { close }.to raise_error(Dor::Exception, "Trying to close version 2 on #{druid} which has active assemblyWF")
        expect(workflow_client).to have_received(:workflow_status).with(hash_including(workflow: 'assemblyWF'))
      end
    end

    context 'when the object has no assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return(nil)
        allow(workflow_client).to receive(:close_version)
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'opened', version: '2').and_return(Time.new)
        allow(workflow_client).to receive(:active_lifecycle).with(druid: druid, milestone_name: 'submitted', version: '2').and_return(false)
      end

      it 'creates the accessioningWF' do
        close
        expect(workflow_client).to have_received(:workflow_status).with(hash_including(workflow: 'assemblyWF'))
        expect(workflow_client).to have_received(:close_version).with(druid: druid, version: '2', create_accession_wf: true)
      end
    end

    context 'when the latest version does not have a tag and a description' do
      subject(:close) do
        described_class.close(cocina_object,
                              description: nil,
                              significance: nil,
                              event_factory: event_factory)
      end

      before do
        # stub out calls for open_for_versioning?
        allow(workflow_client).to receive(:active_lifecycle).and_return(true, false)
        allow(workflow_client).to receive(:workflow_status).with(hash_including(workflow: 'assemblyWF')).and_return('completed')
        allow(workflow_client).to receive(:close_version)
      end

      it 'closes the object version' do
        close
        object_version = ObjectVersion.find_by(druid: druid, version: 2)
        expect(object_version.tag).to be_nil
        expect(object_version.description).to be_nil
        expect(workflow_client).to have_received(:close_version)
          .with(druid: druid, version: '2', create_accession_wf: true)
      end
    end
  end
end
