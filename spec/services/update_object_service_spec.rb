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
          create(:ar_dro, external_identifier: druid)
        end

        it 'raises' do
          expect { store.update }.to raise_error(StandardError, "Updating repository item #{druid} without an open version")
        end
      end

      context 'when version is not open but skipping open check' do
        let(:open) { false }
        let(:store) { described_class.new(cocina_object:, skip_lock: false, skip_open_check: true) }

        let(:lock) { "#{druid}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(repository_object.head_version.to_cocina, lock,
                                       created: repository_object.head_version.created_at.utc,
                                       modified: repository_object.head_version.updated_at.utc)
                        .new(label: 'new label')
        end

        before do
          create(:ar_dro, external_identifier: druid)
          allow(Honeybadger).to receive(:notify)
        end

        it 'does not notify honeybadger' do
          expect(store.update).to be_a Cocina::Models::DROWithMetadata
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end

    context 'when object is an AdminPolicy' do
      let!(:repository_object) { create(:repository_object, :admin_policy, :with_repository_object_version, external_identifier: druid, version: 1) }

      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new({
                                          cocinaVersion: '0.0.1',
                                          externalIdentifier: druid,
                                          type: Cocina::Models::ObjectType.admin_policy,
                                          label: 'Updated Test Admin Policy',
                                          version: 1,
                                          administrative: {
                                            hasAdminPolicy: 'druid:hy787xj5878',
                                            hasAgreement: 'druid:bb033gt0615',
                                            accessTemplate: { view: 'world', download: 'world' }
                                          }
                                        })
      end

      it 'saves to datastore' do
        expect(store.update).to be_a Cocina::Models::AdminPolicyWithMetadata
        expect(repository_object.reload.head_version.label).to eq 'Updated Test Admin Policy'
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
