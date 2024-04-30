# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateObjectService do
  include Dry::Monads[:result]
  let(:store) { described_class.new(cocina_object:, skip_lock: true, skip_open_check: false) }
  let(:open) { true }
  let(:druid) { 'druid:zr174jb7823' }
  let!(:repository_object) { create(:repository_object, :with_repository_object_version, external_identifier: druid, version: 1) }

  describe '#update' do
    before do
      allow(Cocina::ObjectValidator).to receive(:validate)
      allow(VersionService).to receive(:open?).and_return(open)
      allow(Indexer).to receive(:reindex_later)
    end

    context 'when object is a DRO' do
      context 'when skipping lock' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: druid,
                                    type: Cocina::Models::ObjectType.book,
                                    label: 'Changed Test DRO',
                                    version: 1,
                                    description: {
                                      title: [{ value: 'Changed Test DRO' }],
                                      purl: 'https://purl.stanford.edu/zr174jb7823'
                                    },
                                    access: { view: 'world', download: 'world' },
                                    administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                    structural: {},
                                    identification: { sourceId: 'sul:123' }
                                  })
        end

        it 'saves to datastore' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(repository_object.reload.head_version.label).to eq 'Changed Test DRO'
        end
      end

      context 'when checking lock succeeds' do
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: false) }

        let(:lock) { "#{druid}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock, created: repository_object.created_at.utc, modified: repository_object.updated_at.utc)
                        .new(label: 'new label')
        end

        before do
          create(:ar_dro, external_identifier: druid)
        end

        it 'saves to datastore' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(repository_object.reload.opened_version.label).to eq 'new label'
        end
      end

      context 'when checking lock fails' do
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: false) }
        let(:lock) { '64e8320d19d62ddb73c501276c5655cf' }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock, created: repository_object.created_at.utc, modified: repository_object.updated_at.utc)
                        .new(label: 'new label')
        end

        before do
          create(:ar_dro, external_identifier: druid)
        end

        it 'saves to datastore' do
          expect { store.update }.to raise_error(CocinaObjectStore::StaleLockError)
        end
      end

      context 'when version is not open' do
        let(:open) { false }
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: false) }

        let(:lock) { "#{druid}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock, created: repository_object.created_at.utc, modified: repository_object.updated_at.utc)
                        .new(label: 'new label')
        end

        before do
          allow(Honeybadger).to receive(:notify)
          create(:ar_dro, external_identifier: druid)
        end

        it 'notifies honeybadger' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(Honeybadger).to have_received(:notify).with('Updating repository item without an open version',
                                                             context: { druid:, version: 1 })
        end
      end

      context 'when version is not open but skipping open check' do
        let(:open) { false }
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: true) }

        let(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { "#{ar_cocina_object.external_identifier}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
                        .new(label: 'new label')
        end

        before do
          allow(Honeybadger).to receive(:notify)
        end

        it 'does not notify honeybadger' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when repository_object_create is enabled' do
        before do
          allow(Settings.enabled_features).to receive(:repository_object_create).and_return(true)
          ObjectVersion.create(druid: ar_cocina_object.external_identifier, version: 1, description: 'test description')
          allow(VersionService).to receive(:new).and_return(version_service)
          allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
        end

        let(:workflow_client) do
          instance_double(Dor::Workflow::Client,
                          status: instance_double(Dor::Workflow::Client::Status, status_time: nil, display_simplified: 'Registered'))
        end
        let(:version_service) do
          instance_double(VersionService, open?: true)
        end

        let(:ar_cocina_object) { create(:ar_dro) }
        let(:cocina_object) { ar_cocina_object.to_cocina_with_metadata }

        it 'migrates the repository object' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          migrated_version = RepositoryObject.find_by(external_identifier: ar_cocina_object.external_identifier).head_version
          expect(migrated_version.to_cocina).to eq Cocina::Models.without_metadata(cocina_object)
        end
      end
    end

    context 'when object is an AdminPolicy' do
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new({
                                          cocinaVersion: '0.0.1',
                                          externalIdentifier: 'druid:jt959wc5586',
                                          type: Cocina::Models::ObjectType.admin_policy,
                                          label: 'Test Admin Policy',
                                          version: 1,
                                          administrative: {
                                            hasAdminPolicy: 'druid:hy787xj5878',
                                            hasAgreement: 'druid:bb033gt0615',
                                            accessTemplate: { view: 'world', download: 'world' }
                                          }
                                        })
      end

      it 'saves to datastore' do
        expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
        expect(store.update).to be_a Cocina::Models::AdminPolicyWithMetadata
        expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
      end
    end

    context 'when object is a Collection' do
      let!(:repository_object) { create(:repository_object, :collection, :with_repository_object_version, external_identifier: druid, version: 1) }

      let(:cocina_object) do
        Cocina::Models::Collection.new({
                                         cocinaVersion: '0.0.1',
                                         externalIdentifier: druid,
                                         type: Cocina::Models::ObjectType.collection,
                                         label: 'Test Collection',
                                         description: {
                                           title: [{ value: 'Updated title' }],
                                           purl: 'https://purl.stanford.edu/zr174jb7823'
                                         },
                                         version: 1,
                                         access: { view: 'world' },
                                         administrative: {
                                           hasAdminPolicy: 'druid:hy787xj5878'
                                         },
                                         identification: { sourceId: 'sul:123' }
                                       })
      end

      before do
        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'saves to datastore' do
        expect(store.update).to be_a Cocina::Models::CollectionWithMetadata
        expect(repository_object.reload.head_version.to_cocina.description.title.first.value).to eq 'Updated title'
        expect(PublishItemsModifiedJob).to have_received(:perform_later)
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object) do
        build(:collection, source_id: 'sul:PC0170_s3_USC_2010-10-09_141959_0031')
      end

      before do
        # Create a existing record without a source id
        create(:repository_object, :collection, :with_repository_object_version, external_identifier: cocina_object.externalIdentifier)

        # Create a duplicate record with the same sourceId
        create(:repository_object, :collection, :with_repository_object_version, external_identifier: 'druid:dd645sg2172', source_id: cocina_object.identification.sourceId)

        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'raises' do
        expect { store.update }.to raise_error(Cocina::ValidationError)
        expect(PublishItemsModifiedJob).not_to have_received(:perform_later)
      end
    end
  end
end
