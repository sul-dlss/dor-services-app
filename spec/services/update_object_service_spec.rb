# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateObjectService do
  include Dry::Monads[:result]

  let(:store) { described_class.new(cocina_object:, skip_lock: true, skip_open_check: false, who:, description:) }
  let(:who) { 'test_user' }
  let(:description) { 'updating stuff' }
  let(:open) { true }
  let(:druid) { 'druid:zr174jb7823' }
  let!(:repository_object) do
    create(:repository_object, :with_repository_object_version, external_identifier: druid, version: 1)
  end

  describe '#update' do
    before do
      allow(Cocina::ObjectValidator).to receive(:validate)
      allow(VersionService).to receive(:open?).and_return(open)
      allow(Indexer).to receive(:reindex_later)
      allow(EventFactory).to receive(:create)
    end

    context 'when refreshing the description' do
      let(:refresh_enabled) { true }
      let(:catalog_links) { [{ catalog: 'folio', catalogRecordId: 'a999123', refresh: true }] }
      let(:cocina_object) do
        object = repository_object.to_cocina_with_metadata
        object.new(identification: object.identification.new(catalogLinks: catalog_links))
      end
      let(:store) { described_class.new(cocina_object:, who:, description:) }
      let(:marc) do
        { fields: [{ '245' => { 'ind1' => '1', 'ind2' => '0',
                                'subfields' => [{ 'a' => 'Title from FOLIO' }] } }] }.with_indifferent_access
      end
      let(:marc_service) { instance_double(Catalog::MarcService, marc:) }

      before do
        allow(Settings.enabled_features).to receive(:refresh_folio_description_on_update).and_return(refresh_enabled)
        allow(Catalog::MarcService).to receive(:new).and_return(marc_service)
        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'updates the object and refreshes the FOLIO description' do
        updated_object = store.update

        expect(updated_object.description.title.first.value).to eq 'Title from FOLIO'
        expect(updated_object.description.purl).to eq cocina_object.description.purl
        expect(repository_object.reload.to_cocina.description).to eq updated_object.description
        expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a999123',
                                                                 create_marc_if_missing: true)
        expect(EventFactory).to have_received(:create).with(
          druid:, event_type: 'update',
          data: { who:, description:, success: true, request: Cocina::Models.without_metadata(updated_object).to_h }
        )
      end

      context 'when auto refresh is disabled' do
        let(:refresh_enabled) { false }

        it 'keeps the supplied description without fetching from FOLIO' do
          expect(store.update.description).to eq cocina_object.description
          expect(Catalog::MarcService).not_to have_received(:new)
        end
      end

      context 'when refresh is explicitly skipped' do
        let(:store) { described_class.new(cocina_object:, auto_refresh_description: false) }

        it 'keeps the supplied description without fetching FOLIO' do
          expect(store.update.description).to eq cocina_object.description
          expect(Catalog::MarcService).not_to have_received(:new)
        end
      end

      context 'when the HRID is not refreshable' do
        let(:catalog_links) { [{ catalog: 'folio', catalogRecordId: 'a999123', refresh: false }] }

        it 'keeps the supplied description without fetching FOLIO' do
          expect(store.update.description).to eq cocina_object.description
          expect(Catalog::MarcService).not_to have_received(:new)
        end
      end

      context 'when there is no HRID' do
        let(:catalog_links) { [] }

        it 'keeps the supplied description without fetching FOLIO' do
          expect(store.update.description).to eq cocina_object.description
          expect(Catalog::MarcService).not_to have_received(:new)
        end
      end

      context 'when the refresh produces no description' do
        let(:marc) { { fields: [] } }

        it 'keeps the supplied description' do
          expect(store.update.description).to eq cocina_object.description
          expect(marc_service).to have_received(:marc)
        end
      end

      context 'when FOLIO raises an error' do
        before do
          allow(marc_service).to receive(:marc).and_raise(Catalog::Errors::RecordNotFoundError)
        end

        it 'propagates the error without persisting the update' do
          expect { store.update }.to raise_error(Catalog::Errors::RecordNotFoundError)
          expect(repository_object.reload.to_cocina.description).to eq cocina_object.description
          expect(Indexer).not_to have_received(:reindex_later)
        end
      end

      context 'when the version is closed' do
        let(:open) { false }

        it 'rejects the update without fetching FOLIO' do
          expect { store.update }.to raise_error(StandardError, /without an open version/)
          expect(Catalog::MarcService).not_to have_received(:new)
        end
      end

      context 'when FOLIO changes a collection title' do
        let!(:repository_object) do
          create(:repository_object, :collection, :with_repository_object_version, external_identifier: druid)
        end

        it 'persists the refreshed title and schedules member updates' do
          expect(store.update.description.title.first.value).to eq 'Title from FOLIO'
          expect(repository_object.reload.to_cocina.description.title.first.value).to eq 'Title from FOLIO'
          expect(PublishItemsModifiedJob).to have_received(:perform_later).with(druid)
        end
      end
    end

    context 'when object is a DRO' do
      context 'when skipping lock' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: druid,
                                    type: Cocina::Models::ObjectType.book,
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

        it 'saves to datastore and sends event data to EventFactory' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(repository_object.reload.head_version.to_cocina.description.title.first.value).to eq 'Changed Test DRO'
          expect(EventFactory).to have_received(:create).with(
            druid:,
            event_type: 'update',
            data: { who:, description:, success: true, request: cocina_object.to_h }
          )
        end
      end

      context 'when checking lock succeeds' do
        let(:store) do
          described_class.new(cocina_object:, skip_lock: false, skip_open_check: false, who:, description:)
        end

        let(:lock) { "#{druid}=#{repository_object.lock}=#{repository_object.head_version.lock}" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock,
                                       created: repository_object.created_at.utc,
                                       modified: repository_object.updated_at.utc)
        end

        it 'saves to datastore' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
        end
      end

      context 'when checking lock fails' do
        let(:store) do
          described_class.new(cocina_object:, skip_lock: false, skip_open_check: false, who:, description:)
        end
        let(:lock) { '64e8320d19d62ddb73c501276c5655cf' }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock,
                                       created: repository_object.created_at.utc,
                                       modified: repository_object.updated_at.utc)
        end

        it 'saves to datastore' do
          expect { store.update }.to raise_error(CocinaObjectStore::StaleLockError)
        end
      end

      context 'when version is not open' do
        let(:open) { false }
        let(:store) do
          described_class.new(cocina_object:, skip_lock: false, skip_open_check: false, who:, description:)
        end

        let(:lock) { "#{druid}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock,
                                       created: repository_object.created_at.utc,
                                       modified: repository_object.updated_at.utc)
        end

        it 'raises' do
          expect do
            store.update
          end.to raise_error(StandardError, "Updating repository item #{druid} without an open version")
        end
      end

      context 'when version is not open but skipping open check' do
        let(:open) { false }
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: true, who:, description:) }

        let(:lock) { "#{druid}=#{repository_object.lock}=#{repository_object.head_version.lock}" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock,
                                       created: repository_object.head_version.created_at.utc,
                                       modified: repository_object.head_version.updated_at.utc)
        end

        before do
          allow(Honeybadger).to receive(:notify)
        end

        it 'does not notify honeybadger' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end

    context 'when object is an AdminPolicy' do
      let!(:repository_object) do
        create(:repository_object, :admin_policy, :with_repository_object_version, external_identifier: druid,
                                                                                   version: 1)
      end

      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new({
                                          cocinaVersion: '0.0.1',
                                          externalIdentifier: druid,
                                          type: Cocina::Models::ObjectType.admin_policy,
                                          version: 1,
                                          administrative: {
                                            hasAdminPolicy: 'druid:hy787xj5878',
                                            hasAgreement: 'druid:bb033gt0615',
                                            accessTemplate: { view: 'world', download: 'world' }
                                          },
                                          description: {
                                            title: [{ value: 'Updated Test Admin Policy' }],
                                            purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                          }
                                        })
      end

      it 'saves to datastore' do
        expect(store.update).to be_a Cocina::Models::AdminPolicyWithMetadata
        expect(repository_object.reload.head_version.to_cocina.description.title.first.value)
          .to eq 'Updated Test Admin Policy'
      end
    end

    context 'when object is a Collection' do
      let!(:repository_object) do
        create(:repository_object, :collection, :with_repository_object_version, external_identifier: druid, version: 1)
      end

      let(:cocina_object) do
        Cocina::Models::Collection.new({
                                         cocinaVersion: '0.0.1',
                                         externalIdentifier: druid,
                                         type: Cocina::Models::ObjectType.collection,
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
        create(:repository_object, :collection, :with_repository_object_version,
               external_identifier: cocina_object.externalIdentifier)

        # Create a duplicate record with the same sourceId
        create(:repository_object, :collection, :with_repository_object_version,
               external_identifier: 'druid:dd645sg2172', source_id: cocina_object.identification.sourceId)

        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'raises' do
        expect { store.update }.to raise_error(Cocina::ValidationError)
        expect(PublishItemsModifiedJob).not_to have_received(:perform_later)
      end
    end
  end
end
