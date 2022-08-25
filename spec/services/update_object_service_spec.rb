# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateObjectService do
  include Dry::Monads[:result]
  let(:store) { described_class.new(cocina_object:, skip_lock: true) }

  describe '#update' do
    before do
      allow(Cocina::ObjectValidator).to receive(:validate)
    end

    context 'when object is a DRO' do
      context 'when skipping lock (e.g., for a create)' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: 'druid:xz456jk0987',
                                    type: Cocina::Models::ObjectType.book,
                                    label: 'Test DRO',
                                    version: 1,
                                    description: {
                                      title: [{ value: 'Test DRO' }],
                                      purl: 'https://purl.stanford.edu/xz456jk0987'
                                    },
                                    access: { view: 'world', download: 'world' },
                                    administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                    structural: {},
                                    identification: { sourceId: 'sul:123' }
                                  })
        end

        it 'saves to datastore' do
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.update).to be_kind_of Cocina::Models::DROWithMetadata
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when checking lock succeeds' do
        let(:store) { described_class.new(cocina_object:, skip_lock: false) }

        let(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { "#{ar_cocina_object.external_identifier}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
                        .new(label: 'new label')
        end

        it 'saves to datastore' do
          expect(store.update).to be_kind_of Cocina::Models::DROWithMetadata
          expect(Dro.find_by(external_identifier: ar_cocina_object.external_identifier).label).to eq('new label')
        end
      end

      context 'when checking lock fails' do
        let(:store) { described_class.new(cocina_object:, skip_lock: false) }
        let!(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { '64e8320d19d62ddb73c501276c5655cf' }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.updated_at.utc, modified: ar_cocina_object.updated_at.utc)
                        .new(label: 'new label')
        end

        it 'saves to datastore' do
          ar_cocina_object.label = 'someone else changed this label'
          ar_cocina_object.save!
          expect { store.update }.to raise_error(CocinaObjectStore::StaleLockError)
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
        expect(store.update).to be_kind_of Cocina::Models::AdminPolicyWithMetadata
        expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
      end
    end

    context 'when object is a Collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new({
                                         cocinaVersion: '0.0.1',
                                         externalIdentifier: 'druid:hp308wm0436',
                                         type: Cocina::Models::ObjectType.collection,
                                         label: 'Test Collection',
                                         description: {
                                           title: [{ value: 'Updated title' }],
                                           purl: 'https://purl.stanford.edu/hp308wm0436'
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
        # Create a existing record with a different title
        CocinaObjectStore.store(cocina_object.new(
                                  description: {
                                    title: [{ value: 'Original title' }],
                                    purl: 'https://purl.stanford.edu/hp308wm0436'
                                  }
                                ), skip_lock: true)

        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'saves to datastore' do
        expect(store.update).to be_kind_of Cocina::Models::CollectionWithMetadata
        updated_row = Collection.find_by(external_identifier: cocina_object.externalIdentifier)
        expect(updated_row.to_cocina.description.title.first.value).to eq 'Updated title'
        expect(PublishItemsModifiedJob).to have_received(:perform_later)
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object) do
        build(:collection, source_id: 'sul:PC0170_s3_USC_2010-10-09_141959_0031')
      end

      before do
        # Create a existing record without a source id
        CocinaObjectStore.store(cocina_object.new(identification: {}), skip_lock: true)

        # Create a duplicate record with the same sourceId
        CocinaObjectStore.store(cocina_object.new(
                                  externalIdentifier: 'druid:dd645sg2172',
                                  description: {
                                    title: [{ value: 'Test Collection' }],
                                    purl: 'https://purl.stanford.edu/dd645sg2172'
                                  }
                                ), skip_lock: true)

        allow(PublishItemsModifiedJob).to receive(:perform_later)
      end

      it 'raises' do
        expect { store.update }.to raise_error(Cocina::ValidationError)
        expect(PublishItemsModifiedJob).not_to have_received(:perform_later)
      end
    end
  end
end
