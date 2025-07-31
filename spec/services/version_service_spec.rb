# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/LetSetup
RSpec.describe VersionService do
  let(:druid) { 'druid:xz456jk0987' }
  let!(:repository_object) do
    create(:repository_object, :with_repository_object_version, :closed, external_identifier: druid)
  end
  let(:cocina_object) { repository_object.to_cocina_with_metadata }
  let(:version) { 1 }
  let(:workflow_state_service) { instance_double(Workflow::StateService) }

  before do
    allow(Workflow::StateService).to receive(:new).and_return(workflow_state_service)
    allow(Indexer).to receive(:reindex_later)
    allow(EventFactory).to receive(:create).and_return(true)
  end

  describe '.open' do
    subject(:open) do
      described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid',
                           from_version:)
    end

    let(:from_version) { nil }

    before do
      allow(Preservation::Client.objects).to receive(:current_version).and_return(1)
      allow(Workflow::Service).to receive(:create)
      allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
    end

    context 'when on the expected path' do
      it 'creates an object version and starts a workflow' do
        expect(open).to be_a(Cocina::Models::DROWithMetadata)
        expect(workflow_state_service).to have_received(:accessioned?)
        expect(workflow_state_service).to have_received(:accessioning?)
        expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'versioningWF', version: '2')

        expect(EventFactory).to have_received(:create)
          .with(data: { version: '2', who: 'sunetid', description: 'same as it ever was' },
                druid:,
                event_type: 'version_open')

        expect(Indexer).to have_received(:reindex_later).with(druid:)
        expect(repository_object.reload.opened_version.version).to eq 2
        expect(repository_object.opened_version.version_description).to eq 'same as it ever was'
      end
    end

    context 'when skipping the preservation catalog sync' do
      before do
        allow(Settings.version_service).to receive(:sync_with_preservation).and_return false
        allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
      end

      it 'creates an object version and starts a workflow' do
        open

        expect(Preservation::Client.objects).not_to have_received(:current_version)
        expect(repository_object.reload.opened_version).to be_present
      end
    end

    context 'when a new version cannot be opened' do
      let(:instance) { described_class.new(druid:, version:) }

      before do
        allow(instance).to receive(:ensure_openable!).and_raise(VersionService::VersioningError,
                                                                'Object net yet accessioned')
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(VersionService::VersioningError, 'Object net yet accessioned')
      end
    end

    context "when Preservation's current version is greater than the current version" do
      it 'raises an exception' do
        allow(Preservation::Client.objects).to receive(:current_version).and_return(3)
        expect do
          open
        end.to raise_error(VersionService::VersioningError,
                           'Version from Preservation is out of sync. Preservation expects 3 but current version is 1')
      end
    end

    context "when Preservation doesn't know about the object" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).and_raise(Preservation::Client::NotFoundError)
      end

      it 'raises an exception' do
        errmsg = 'Preservation (SDR) is not yet answering queries about this object. When an object has just been ' \
                 'transferred, Preservation isn\'t immediately ready to answer queries.'
        expect { open }.to raise_error(VersionService::VersioningError, errmsg)
      end
    end

    context 'when a from version is provided' do
      let(:from_version) { 1 }

      before do
        repository_object.open_version!(description: 'A new version')
        repository_object.head_version.update!(label: 'New version label')
        repository_object.close_version!
      end

      it 'creates an object version and starts a workflow' do
        expect(open).to be_a(Cocina::Models::DROWithMetadata)
        expect(open.label).not_to eq 'New version label'
        expect(workflow_state_service).to have_received(:accessioned?)
        expect(workflow_state_service).to have_received(:accessioning?)
        expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'versioningWF', version: '3')

        expect(EventFactory).to have_received(:create)
          .with(data: { version: '3', who: 'sunetid', description: 'same as it ever was' },
                druid:,
                event_type: 'version_open')

        expect(Indexer).to have_received(:reindex_later).with(druid:)
        expect(repository_object.reload.opened_version.version).to eq 3
        expect(repository_object.opened_version.version_description).to eq 'same as it ever was'
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
      let!(:repository_object) { create(:repository_object, :closed, external_identifier: druid) }

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
                            user_version_mode:)
    end

    let(:version) { 2 }
    let(:start_accession) { true }
    let(:user_version_mode) { :none }
    let(:description) { 'closing text' }

    let(:repository_object) { create(:repository_object, :with_repository_object_version, external_identifier: druid) }

    before do
      repository_object.save!
      repository_object.head_version.update!(version: 2, version_description: 'A Second Version')
      allow(Workflow::Service).to receive(:create)
      allow(UserVersionService).to receive(:permanently_withdraw_previous_user_versions)
    end

    context 'when description and user_name are passed in' do
      before do
        allow(workflow_state_service).to receive_messages(accessioning?: false, assembling?: false)
      end

      context 'when user_version is none' do
        it 'does not create a user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.version_description).to eq('closing text')

          expect(EventFactory).to have_received(:create)
            .with(data: { version: '2', who: 'jcoyne', description: 'closing text' },
                  druid:,
                  event_type: 'version_close')

          expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'accessionWF', version: '2')

          expect(repository_object.last_closed_version.user_versions.count).to eq 0
        end
      end

      context 'when user_version is new' do
        let(:user_version_mode) { :new }

        it 'creates a new user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.user_versions.count).to eq 1
          expect(repository_object.last_closed_version.user_versions.first.version).to eq 1
        end
      end

      context 'when user_version is new and there is an existing user version' do
        let(:user_version_mode) { :new }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version_mode: :new)
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator,
                                                                                     validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'creates a new user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.user_versions.count).to eq 1
          expect(repository_object.last_closed_version.user_versions.first.version).to eq 2
        end
      end

      context 'when user_version is update' do
        let(:user_version_mode) { :update }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version_mode: :new)
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator,
                                                                                     validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          allow(UserVersionService).to receive(:move).and_call_original
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'moves the user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.user_versions.count).to eq 1
          expect(repository_object.last_closed_version.user_versions.first.version).to eq 1
          expect(repository_object.versions.find_by(version: 2).user_versions.count).to eq 0
          expect(UserVersionService).to have_received(:move).with(druid:, version: 3, user_version: 1, publish: false)
        end
      end

      context 'when user_version is update but there is no previous user version' do
        let(:user_version_mode) { :update }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version_mode: :none)
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator,
                                                                                     validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'creates a new user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.user_versions.count).to eq 1
          expect(repository_object.last_closed_version.user_versions.first.version).to eq 1
        end
      end

      context 'when user_version is update_if_existing' do
        let(:user_version_mode) { :update_if_existing }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version_mode: :new)
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator,
                                                                                     validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'moves the user version' do
          close
          expect(repository_object.reload.last_closed_version).to be_present
          expect(repository_object.last_closed_version.user_versions.count).to eq 1
          expect(repository_object.last_closed_version.user_versions.first.version).to eq 1
          expect(repository_object.versions.find_by(version: 2).user_versions.count).to eq 0
        end
      end

      context 'when user_version is update_if_existing but there is no previous user version' do
        let(:user_version_mode) { :update_if_existing }
        let(:version) { 3 }

        before do
          described_class.close(druid:,
                                version: 2,
                                description:,
                                user_name: 'jcoyne',
                                start_accession:,
                                user_version_mode: :none)
          allow(Cocina::ObjectValidator).to receive(:new).and_return(instance_double(Cocina::ObjectValidator,
                                                                                     validate: true))
          allow(Preservation::Client.objects).to receive(:current_version).and_return(2)
          allow(workflow_state_service).to receive_messages(accessioned?: true, accessioning?: false)
          allow(cocina_object).to receive(:version).and_return(2)
          described_class.open(cocina_object:, description: 'same as it ever was', opening_user_name: 'sunetid')
          repository_object.versions.last.update!(closed_at: nil)
          repository_object.head_version = repository_object.versions.last
          repository_object.last_closed_version = repository_object.versions.first
        end

        it 'does nothing' do
          close
          expect(repository_object.last_closed_version.user_versions).to be_empty
          expect(repository_object.user_versions).to be_empty
        end
      end
    end

    context 'when start_accession is false' do
      let(:start_accession) { false }

      before do
        allow(workflow_state_service).to receive_messages(accessioning?: false, assembling?: false)
      end

      it 'does not create accessionWF' do
        close
        expect(repository_object.reload.last_closed_version).to be_present

        expect(Workflow::Service).not_to have_received(:create)
      end
    end

    context 'when the object has not been opened for versioning' do
      let!(:repository_object) { create(:repository_object, :closed, external_identifier: druid) }

      it 'raises an exception' do
        expect do
          close
        end.to raise_error(VersionService::VersioningError,
                           "Trying to close version 2 on #{druid} which is not opened for versioning")
      end
    end

    context 'when the object has an active accesssionWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: true)
      end

      it 'raises an exception' do
        expect do
          close
        end.to raise_error(VersionService::VersioningError, "accessionWF already created for versioned object #{druid}")
      end
    end

    context 'when the object has an active assemblyWF' do
      before do
        allow(workflow_state_service).to receive_messages(assembling?: true)
      end

      it 'raises an exception' do
        expect do
          close
        end.to raise_error(VersionService::VersioningError,
                           "Trying to close version 2 on #{druid} which has active assemblyWF")
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
        expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'accessionWF', version: '2')
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
        expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'accessionWF', version: '2')
      end
    end

    context 'when multiple user versions and access is dark' do
      let(:version) { 3 }

      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: false)
        repository_object.close_version!
        repository_object.open_version!(description: 'A new version')
        repository_object.head_version.update!(access: { view: 'dark', download: 'none' })
        create(:user_version, repository_object_version: repository_object.versions.first)
        create(:user_version, repository_object_version: repository_object.versions.first)
      end

      it 'permanently withdraws previous user versions' do
        close
        expect(UserVersionService).to have_received(:permanently_withdraw_previous_user_versions).with(druid:)
      end
    end

    context 'when multiple user versions and access is not dark' do
      let(:version) { 3 }

      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: false)
        repository_object.close_version!
        repository_object.open_version!(description: 'A new version')
        create(:user_version, repository_object_version: repository_object.versions.first)
        create(:user_version, repository_object_version: repository_object.versions.first)
      end

      it 'does not permanently withdraw' do
        close
        expect(UserVersionService).not_to have_received(:permanently_withdraw_previous_user_versions)
      end
    end

    context 'when single user versions and access is dark' do
      let(:version) { 3 }

      before do
        allow(workflow_state_service).to receive_messages(assembling?: false, accessioning?: false)
        repository_object.head_version.update!(access: { view: 'dark', download: 'none' })
        repository_object.close_version!
        repository_object.open_version!(description: 'A new version')
        create(:user_version, repository_object_version: repository_object.versions.first)
      end

      it 'does not permanently withdraw' do
        close
        expect(UserVersionService).not_to have_received(:permanently_withdraw_previous_user_versions)
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

  describe '.can_discard?' do
    subject(:can_discard) do
      described_class.can_discard?(druid:, version:)
    end

    let(:version) { 2 }

    before do
      # Starts with version 1 being closed.
      repository_object.open_version!(description: 'A new version')
    end

    context 'when version is not the head version' do
      let(:version) { 1 }

      it 'returns false' do
        expect(can_discard).to be false
      end
    end

    context 'when version is not open' do
      before do
        repository_object.close_version!
      end

      it 'returns false' do
        expect(can_discard).to be false
      end
    end

    context 'when the version is discardable' do
      it 'returns true' do
        expect(can_discard).to be true
      end
    end
  end

  describe '.ensure_discardable!' do
    subject(:ensure_discardable!) do
      described_class.ensure_discardable!(druid:, version:)
    end

    let(:version) { 2 }

    before do
      # Starts with version 1 being closed.
      repository_object.open_version!(description: 'A new version')
    end

    context 'when version is not the head version' do
      let(:version) { 1 }

      it 'raises' do
        expect do
          ensure_discardable!
        end.to raise_error(VersionService::VersioningError, 'Only the head version can be discarded')
      end
    end

    context 'when version is not open' do
      before do
        repository_object.close_version!
      end

      it 'raises' do
        expect do
          ensure_discardable!
        end.to raise_error(VersionService::VersioningError,
                           'Cannot discard version because head version is closed')
      end
    end

    context 'when the version is discardable' do
      it 'does not raise' do
        expect { ensure_discardable! }.not_to raise_error
      end
    end
  end

  describe '.discard' do
    subject(:discard) do
      described_class.discard(druid:, version:)
    end

    let(:version) { 2 }

    before do
      # Starts with version 1 being closed.
      repository_object.open_version!(description: 'A new version')
    end

    context 'when version is discardable' do
      let(:version) { 1 }

      it 'raises' do
        expect { discard }.to raise_error(VersionService::VersioningError)
      end
    end

    context 'when the version is discardable' do
      it 'discards the repository object version' do
        discard
        expect(repository_object.reload.opened_version).to be_nil
        expect(repository_object.head_version).to eq repository_object.versions.first
        expect(repository_object.versions.count).to eq 1

        expect(EventFactory).to have_received(:create)
          .with(data: { version: }, druid:, event_type: 'version_discard')
      end
    end
  end
end
# rubocop:enable RSpec/LetSetup
