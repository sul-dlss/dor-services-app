# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  describe 'to Fedora' do
    let(:item) { instance_double(Dor::Item) }
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }
    let(:druid) { 'druid:bc123df4567' }

    before do
      allow(ActiveFedora::ContentModel).to receive(:models_asserted_by).and_return(['info:fedora/afmodel:Item'])
    end

    describe '#find' do
      context 'when DRO is found' do
        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
        end

        it 'returns Cocina object' do
          expect(described_class.find(druid)).to eq cocina_object
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::Mapper).to have_received(:build).with(item)
        end
      end

      context 'when DRO is not found' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'returns Cocina object' do
          expect { described_class.find(druid) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end
    end

    describe '#save' do
      context 'when object is found in datastore' do
        let(:updated_cocina_object) { instance_double(Cocina::Models::DRO) }

        before do
          allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
          allow(Notifications::ObjectUpdated).to receive(:publish)
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run).and_return(updated_cocina_object)
        end

        it 'maps and saves to Fedora' do
          expect(described_class.save(cocina_object)).to be updated_cocina_object
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::ObjectUpdater).to have_received(:run).with(item, cocina_object)
          expect(Notifications::ObjectUpdated).to have_received(:publish).with(model: updated_cocina_object)
        end
      end

      context 'when object is not found in datastore' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'returns Cocina object' do
          expect { described_class.save(cocina_object) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end
    end
  end

  describe 'to ActiveRecord' do
    let(:store) { described_class.new }

    describe '#ar_to_cocina_find' do
      context 'when object is not found in datastore' do
        it 'raises' do
          expect { store.send(:ar_to_cocina_find, 'druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when object is a DRO' do
        let(:ar_cocina_object) { create(:dro) }

        it 'returns Cocina::Models::DRO' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_a(Cocina::Models::DRO)
        end
      end

      context 'when object is an AdminPolicy' do
        let(:ar_cocina_object) { create(:admin_policy) }

        it 'returns Cocina::Models::AdminPolicy' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_a(Cocina::Models::AdminPolicy)
        end
      end

      context 'when object is a Collection' do
        let(:ar_cocina_object) { create(:collection) }

        it 'returns Cocina::Models::Collection' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_a(Cocina::Models::Collection)
        end
      end
    end

    describe '#cocina_to_ar_save' do
      let(:store) { described_class.new }

      context 'when object is a DRO' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: 'druid:xz456jk0987',
                                    type: Cocina::Models::Vocab.book,
                                    label: 'Test DRO',
                                    version: 1,
                                    access: { access: 'world', download: 'world' },
                                    administrative: { hasAdminPolicy: 'druid:hy787xj5878' }
                                  })
        end

        it 'saves to datastore' do
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to be(cocina_object)
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when object is an AdminPolicy' do
        let(:cocina_object) do
          Cocina::Models::AdminPolicy.new({
                                            cocinaVersion: '0.0.1',
                                            externalIdentifier: 'druid:jt959wc5586',
                                            type: Cocina::Models::Vocab.admin_policy,
                                            label: 'Test Admin Policy',
                                            version: 1,
                                            administrative: { hasAdminPolicy: 'druid:hy787xj5878', hasAgreement: 'druid:bb033gt0615' }
                                          })
        end

        it 'saves to datastore' do
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to be(cocina_object)
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when object is a Collection' do
        let(:cocina_object) do
          Cocina::Models::Collection.new({
                                           cocinaVersion: '0.0.1',
                                           externalIdentifier: 'druid:hp308wm0436',
                                           type: Cocina::Models::Vocab.collection,
                                           label: 'Test Collection',
                                           version: 1,
                                           access: { access: 'world' }
                                         })
        end

        it 'saves to datastore' do
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to be(cocina_object)
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end
    end
  end
end
