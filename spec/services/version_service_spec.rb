# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/LetSetup
RSpec.describe VersionService do
  let(:druid) { 'druid:xz456jk0987' }
  let(:cocina_object) { create(:ar_dro, external_identifier: druid).to_cocina_with_metadata }
  let(:version) { 1 }
  let(:workflow_state_service) { instance_double(WorkflowStateService) }
  let!(:repository_object) { create(:repository_object, :closed, external_identifier: druid) }

  before do
    allow(WorkflowStateService).to receive(:new).and_return(workflow_state_service)
    allow(Indexer).to receive(:reindex_later)
    allow(EventFactory).to receive(:create).and_return(true)
  end

  describe '.open' do
    subject(:open) { described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid') }

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client, create_workflow_by_name: true)
    end

    before do
      allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator, validate: true))
      ObjectVersion.create(druid:, version: 1, description: 'new version')
      allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
      allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
    end

    context 'when on the expected path' do
      it 'creates an object version and starts a workflow' do
        open
        expect(Dro.find_by(external_identifier: druid).version).to eq 2
        expect(ObjectVersion.current_version(druid).version).to eq(2)
        expect(workflow_state_service).to have_received(:accessioned?)
        expect(workflow_state_service).to have_received(:accessioning?)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'versioningWF', version: '2')

        current_version = ObjectVersion.current_version(druid)
        expect(current_version.version).to eq(2)
        expect(current_version.description).to eq('same as it ever was')

        expect(EventFactory).to have_received(:create).with(data: { version: '2', who: 'sunetid' },
                                                            druid:,
                                                            event_type: 'version_open')
        expect(repository_object.reload.opened_version.version).to eq 2
        expect(repository_object.opened_version.version_description).to eq 'same as it ever was'
      end
    end

    context 'when skipping the preservation catalog sync' do
      before do
        allow(Settings.version_service).to receive(:sync_with_preservation).and_return false
        allow(ObjectVersion).to receive(:sync_then_increment_version)
        allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
      end

      it 'creates an object version and starts a workflow' do
        open
        expect(Dro.find_by(external_identifier: druid).version).to eq 2
        expect(ObjectVersion.current_version(druid).version).to eq(2)
        expect(ObjectVersion).not_to have_received(:sync_then_increment_version)
        expect(workflow_state_service).to have_received(:accessioned?)
        expect(workflow_state_service).to have_received(:accessioning?)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'versioningWF', version: '2')

        expect(EventFactory).to have_received(:create).with(data: { version: '2', who: 'sunetid' },
                                                            druid:,
                                                            event_type: 'version_open')
        expect(repository_object.reload.opened_version).to be_present
      end
    end

    context 'when a new version cannot be opened' do
      let(:instance) { described_class.new(druid:, version:) }

      before do
        allow(instance).to receive(:ensure_openable!).and_raise(VersionService::VersioningError, 'Object net yet accessioned')
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(VersionService::VersioningError, 'Object net yet accessioned')
      end
    end

    context "when Preservation's current version is greater than the current version" do
      it 'raises an exception' do
        expect(Preservation::Client.objects).to receive(:current_version).and_return(3)
        expect { open }.to raise_error(VersionService::VersioningError, 'Cannot sync to a version greater than current: 1, requested 3')
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises an exception' do
        errmsg = "Preservation (SDR) is not yet answering queries about this object. When an object has just been transferred, Preservation isn't immediately ready to answer queries."
        expect { open }.to raise_error(VersionService::VersioningError, errmsg)
      end
    end
  end

  describe '.open?' do
    subject(:open?) { described_class.open?(druid:, version:) }

    context 'when open' do
      let!(:repository_object) { create(:repository_object, external_identifier: druid) }

      it 'returns true' do
        expect(open?).to be true
      end
    end

    context 'when not open' do
      it 'returns false' do
        expect(open?).to be false
      end
    end

    context 'when the object is not found' do
      let!(:repository_object) { nil }

      it 'raises an CocinaObjectNotFoundError' do
        expect { open? }.to raise_error(VersionService::CocinaObjectNotFoundError)
      end
    end

    context 'when version mismatch' do
      let!(:repository_object) do
        create(:repository_object, :closed, external_identifier: druid).tap do |repo_obj|
          repo_obj.head_version.update!(version: 3)
        end
      end

      it 'raises an VersioningError' do
        expect { open? }.to raise_error(VersionService::VersioningError)
      end
    end
  end

  describe '.can_open?' do
    subject(:can_open?) { described_class.can_open?(druid:, version:) }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client)
    end

    context 'when a new version can be opened' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
        allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
      end

      it 'returns true' do
        expect(can_open?).to be true
        expect(workflow_state_service).to have_received(:accessioned?)
        expect(workflow_state_service).to have_received(:accessioning?)
      end
    end

    context 'when the object has not been accessioned' do
      before do
        allow(workflow_state_service).to receive(:accessioned?).and_return(false)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_state_service).to have_received(:accessioned?)
      end
    end

    context 'when the object has already been opened' do
      let!(:repository_object) { create(:repository_object, external_identifier: druid) }

      before do
        allow(workflow_state_service).to receive_messages(accessioned?: true)
      end

      it 'returns false' do
        expect(can_open?).to be false
      end
    end

    context 'when the object is still being accessioned' do
      before do
        allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: true)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_state_service).to have_received(:accessioning?)
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: true)
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      it 'returns false' do
        expect(can_open?).to be false
      end
    end
  end

  describe '.close' do
    subject(:close) do
      described_class.close(druid:, version:,
                            description:,
                            user_name: 'jcoyne',
                            start_accession:,
                            user_version: user_version_param)
    end

    let(:version) { 2 }
    let(:start_accession) { true }
    let(:user_version_param) { 'none' }
    let(:description) { 'closing text' }
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client, create_workflow_by_name: true)
    end

    let(:repository_object) { create(:repository_object, external_identifier: druid) }

    before do
      repository_object.save!
      repository_object.head_version.update!(version: 2, version_description: 'A Second Version')
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      ObjectVersion.create(druid:, version: 1, description: 'Initial Version')
      ObjectVersion.create(druid:, version: 2, description: 'A Second Version')
      allow(workflow_client).to receive(:close_version)
    end

    context 'when description and user_name are passed in' do
      before do
        allow(workflow_state_service).to receive_messages(accessioning?: false, assembling?: false)
      end

      context 'when user_version is :none' do
        it 'sets description and an event and does not create a user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.version_description).to eq('closing text')

          object_version = ObjectVersion.find_by(druid:, version: 2)
          expect(object_version.description).to eq('closing text')
          expect(EventFactory).to have_received(:create).with(data: { version: '2', who: 'jcoyne' },
                                                              druid:,
                                                              event_type: 'version_close')

          expect(workflow_client).to have_received(:close_version)
            .with(druid:, version: '2', create_accession_wf: true)

          expect(repository_object.last_closed_version.user_versions.count).to eq 0
        end
      end

      context 'when user_version is :new' do
        let(:user_version_param) { 'new' }

        it 'sets description and an event and creates a new user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.version_description).to eq('closing text')

          object_version = ObjectVersion.find_by(druid:, version: 2)
          expect(object_version.description).to eq('closing text')
          expect(EventFactory).to have_received(:create).with(data: { version: '2', who: 'jcoyne' },
                                                              druid:,
                                                              event_type: 'version_close')

          expect(workflow_client).to have_received(:close_version)
            .with(druid:, version: '2', create_accession_wf: true)

          expect(repository_object.last_closed_version.user_versions.count).to eq 1
        end
      end

      context 'when user_version is :update' do
        let(:user_version_param) { 'update' }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version: 'new')
          ObjectVersion.create(druid:, version:, description: 'new version')
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator, validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'sets description and an event and creates a new user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.version_description).to eq('closing text')

          object_version = ObjectVersion.find_by(druid:, version: 2)
          expect(object_version.description).to eq('closing text')
          expect(EventFactory).to have_received(:create).with(data: { version: '2', who: 'jcoyne' },
                                                              druid:,
                                                              event_type: 'version_close')

          expect(workflow_client).to have_received(:close_version)
            .with(druid:, version: '2', create_accession_wf: true)

          expect(repository_object.last_closed_version.user_versions.count).to eq 1
        end
      end
    end

    context 'when start_accession is false' do
      let(:start_accession) { false }

      before do
        allow(workflow_state_service).to receive_messages(accessioning?: false, assembling?: false)
      end

      it 'passes the correct value of create_accession_wf' do
        close
        expect(repository_object.reload.last_closed_version).to be_present

        expect(workflow_client).to have_received(:close_version)
          .with(druid:, version: '2', create_accession_wf: false)
      end
    end

    context 'when the object has not been opened for versioning' do
      let!(:repository_object) { create(:repository_object, :closed, external_identifier: druid) }

      it 'raises an exception' do
        expect { close }.to raise_error(VersionService::VersioningError, "Trying to close version 2 on #{druid} which is not opened for versioning")
      end
    end

    context 'when the object has an active accesssionWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: true)
      end

      it 'raises an exception' do
        expect { close }.to raise_error(VersionService::VersioningError, "accessionWF already created for versioned object #{druid}")
      end
    end

    context 'when the object has an active assemblyWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: true)
      end

      it 'raises an exception' do
        expect { close }.to raise_error(VersionService::VersioningError, "Trying to close version 2 on #{druid} which has active assemblyWF")
        expect(workflow_state_service).to have_received(:assembling?)
      end
    end

    context 'when the object has no assemblyWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: false)
      end

      it 'creates the accessioningWF' do
        close
        expect(repository_object.reload.last_closed_version).to be_present
        expect(workflow_state_service).to have_received(:assembling?)
        expect(workflow_client).to have_received(:close_version).with(druid:, version: '2', create_accession_wf: true)
      end
    end

    context 'when not providing a description' do
      let(:description) { nil }

      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: false)
      end

      it 'closes the object version using existing signficance and description' do
        close
        expect(repository_object.reload.last_closed_version).to be_present
        expect(repository_object.last_closed_version.version_description).to eq 'A Second Version'
        object_version = ObjectVersion.find_by(druid:, version: 2)
        expect(object_version.description).to eq 'A Second Version'
        expect(workflow_client).to have_received(:close_version)
          .with(druid:, version: '2', create_accession_wf: true)
      end
    end
  end

  describe '.can_close?' do
    subject(:can_close) do
      described_class.can_close?(druid:, version:)
    end

    let(:version) { 1 }

    context 'when cloaseable' do
      let!(:repository_object) { create(:repository_object, external_identifier: druid) }

      before do
        allow(workflow_state_service).to receive_messages(accessioning?: false, assembling?: false)
      end

      it 'returns true' do
        expect(can_close).to be true
      end
    end

    context 'when the object has not been opened for versioning' do
      it 'returns false' do
        expect(can_close).to be false
      end
    end

    context 'when the object has an active accesssionWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: true)
      end

      it 'returns false' do
        expect(can_close).to be false
      end
    end

    context 'when the object has an active assemblyWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: true)
      end

      it 'returns false' do
        expect(can_close).to be false
      end
    end
  end
end
# rubocop:enable RSpec/LetSetup
