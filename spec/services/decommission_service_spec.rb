# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DecommissionService do
  let(:cocina_object) { repository_object.head_version.to_cocina_with_metadata }
  let(:druid) { 'druid:hj185xx2222' }
  let(:description) { 'No longer needed' }
  let(:sunetid) { 'awesome_po' }
  let(:apo_object) { build(:admin_policy, id: Settings.graveyard_admin_policy.druid) }

  describe '.decommission' do
    subject(:decommission) do
      described_class.decommission(druid:, description:, sunetid:)
    end

    before do
      allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    end

    context 'when the object can be opened for versioning' do
      let(:repository_object) do
        create(:repository_object, :with_repository_object_version, :closed, external_identifier: druid, version: 1)
      end
      let(:updated_cocina_object) { repository_object.head_version.to_cocina_with_metadata }

      before do
        create(:release_tag, druid:, released_to: 'Searchworks', what: 'self', who: 'bob', release: true,
                             created_at: 1.day.ago.iso8601)
        allow(CocinaObjectStore).to receive(:find).with(Settings.graveyard_admin_policy.druid).and_return(apo_object)
        allow(Settings.version_service).to receive(:sync_with_preservation).and_return false
        allow(Indexer).to receive(:reindex_later)
        allow(Workflow::Service).to receive(:create)
        allow_any_instance_of(Workflow::StateService).to receive(:accessioned?).and_return(true) # rubocop:disable RSpec/AnyInstance
        allow(ReleaseTagService).to receive(:create)
        allow(AdministrativeTags).to receive(:create)
      end

      it 'decommissions the object' do
        expect(decommission).to be_an_instance_of(Cocina::Models::DROWithMetadata)
        repository_object.reload
        expect(ReleaseTagService).to have_received(:create).with(tag: an_instance_of(Dor::ReleaseTag),
                                                                 cocina_object: an_instance_of(Cocina::Models::DROWithMetadata),
                                                                 create_only: true)
        expect(AdministrativeTags).to have_received(:create).with(identifier: druid,
                                                                  tags: ["Decommissioned : #{description}"])
        expect(Indexer).to have_received(:reindex_later).with(druid:).twice
        expect(Workflow::Service).to have_received(:create).with(workflow_name: 'releaseWF', druid:,
                                                                 version: repository_object.head_version_version)
        expect(repository_object.head_version).to be_closed
        expect(updated_cocina_object.structural.contains).to be_empty
        expect(updated_cocina_object.administrative.hasAdminPolicy).to eq(Settings.graveyard_admin_policy.druid)
      end
    end

    context 'when the object cannot be opened for versioning' do
      let(:repository_object) do
        create(:repository_object, :with_repository_object_version, external_identifier: druid, version: 1)
      end

      context 'when it is already opened for versioning' do
        before do
          allow_any_instance_of(Workflow::StateService).to receive(:accessioned?).and_return(true) # rubocop:disable RSpec/AnyInstance
        end

        it 'raises an error' do
          expect { decommission }.to raise_error(VersionService::VersioningError)
            .with_message('Object already opened for versioning')
        end
      end

      context 'when it is not accessioned' do
        it 'raises an error' do
          expect { decommission }.to raise_error(VersionService::VersioningError)
            .with_message('Object net yet accessioned')
        end
      end
    end
  end
end
