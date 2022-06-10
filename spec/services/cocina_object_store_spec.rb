# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  include Dry::Monads[:result]

  let(:store) { described_class.new }

  describe '#find' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.find('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns Cocina::Models::AdminPolicy' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::AdminPolicyWithMetadata)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns Cocina::Models::Collection' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end
  end

  describe '#exists?' do
    context 'when object is not found in datastore' do
      it 'returns false' do
        expect(store.exists?('druid:bc123df4567')).to be(false)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns true' do
        expect(store.exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns true' do
        expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns true' do
        expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
      end
    end
  end

  describe '#save' do
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
          expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::DROWithMetadata
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when checking lock succeeds' do
        let(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { "#{ar_cocina_object.external_identifier}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
        end

        let(:changed_cocina_object) do
          cocina_object.new(label: 'new label')
        end

        it 'saves to datastore' do
          expect(store.save(changed_cocina_object)).to be_kind_of Cocina::Models::DROWithMetadata
          expect(Dro.find_by(external_identifier: ar_cocina_object.external_identifier).label).to eq('new label')
        end
      end

      context 'when checking lock fails' do
        let!(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { '64e8320d19d62ddb73c501276c5655cf' }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.updated_at.utc, modified: ar_cocina_object.updated_at.utc)
        end

        let(:changed_cocina_object) do
          cocina_object.new(label: 'new label')
        end

        it 'saves to datastore' do
          ar_cocina_object.label = 'someone else changed this label'
          ar_cocina_object.save!
          expect { store.send(:cocina_to_ar_save, changed_cocina_object) }.to raise_error(CocinaObjectStore::StaleLockError)
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
        expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::AdminPolicyWithMetadata
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
                                           title: [{ value: 'Test Collection' }],
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

      it 'saves to datastore' do
        expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
        expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::CollectionWithMetadata
        expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object) do
        build(:collection, source_id: 'sul:PC0170_s3_USC_2010-10-09_141959_0031')
      end

      before do
        # Create a duplicate record with the same sourceId
        store.send(:cocina_to_ar_save, cocina_object.new(
                                         externalIdentifier: 'druid:dd645sg2172',
                                         description: {
                                           title: [{ value: 'Test Collection' }],
                                           purl: 'https://purl.stanford.edu/dd645sg2172'
                                         }
                                       ), skip_lock: true)
      end

      it 'raises' do
        expect { store.send(:cocina_to_ar_save, cocina_object, skip_lock: true) }.to raise_error(Cocina::ValidationError)
      end
    end
  end

  describe '#destroy' do
    let!(:dro) { create(:ar_dro) }

    before do
      allow(Notifications::ObjectDeleted).to receive(:publish)
    end

    it 'destroys the object' do
      described_class.destroy(dro.external_identifier)
      expect(Dro).not_to exist(dro.external_identifier)
      expect(Notifications::ObjectDeleted).to have_received(:publish)
    end
  end
end
