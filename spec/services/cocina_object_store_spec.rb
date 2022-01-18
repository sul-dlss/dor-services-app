# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
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
