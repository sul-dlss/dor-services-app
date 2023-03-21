# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::UpdateMarc856RecordService do
  subject(:service) { described_class.new(cocina_object, thumbnail_service:) }

  let(:druid) { 'druid:bc123dg9393' }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }
  let(:cocina_object) { build(:dro, id: druid) }

  describe '.update' do
    before do
      allow(described_class).to receive(:new).and_return(service)
      allow(service).to receive(:update)
    end

    it 'invokes #update on a new instance' do
      described_class.update(cocina_object, thumbnail_service:)
      expect(service).to have_received(:update).once
    end
  end

  describe '#update' do
    context 'when Symphony' do
      before do
        allow(Catalog::Marc856Generator).to receive(:create).and_return(marc_856_data)
        allow(Catalog::SymphonyWriter).to receive(:save)
      end

      let(:marc_856_data) { { indicators: [], subfields: [] } }

      context 'when not an admin policy' do
        it 'calls Marc856Generator and SymphonyWriter' do
          service.update
          expect(Catalog::Marc856Generator).to have_received(:create).with(cocina_object, thumbnail_service:, catalog: 'symphony')
          expect(Catalog::SymphonyWriter).to have_received(:save).with(cocina_object:, marc_856_data:)
        end
      end

      context 'when an admin policy' do
        let(:cocina_object) { build(:admin_policy) }

        it 'does nothing' do
          service.update
          expect(Catalog::Marc856Generator).not_to have_received(:create)
          expect(Catalog::SymphonyWriter).not_to have_received(:save)
        end
      end
    end

    context 'when Folio' do
      before do
        allow(Settings.enabled_features).to receive(:write_folio).and_return(true)
        allow(Catalog::Marc856Generator).to receive(:create).and_return(marc_856_data)
        allow(Catalog::FolioWriter).to receive(:save)
      end

      let(:marc_856_data) { { indicators: [], subfields: [] } }

      context 'when not an admin policy' do
        it 'calls Marc856Generator and FolioWriter' do
          service.update
          expect(Catalog::Marc856Generator).to have_received(:create).with(cocina_object, thumbnail_service:, catalog: 'folio')
          expect(Catalog::FolioWriter).to have_received(:save).with(cocina_object:, marc_856_data:)
        end
      end

      context 'when an admin policy' do
        let(:cocina_object) { build(:admin_policy) }

        it 'does nothing' do
          service.update
          expect(Catalog::Marc856Generator).not_to have_received(:create)
          expect(Catalog::FolioWriter).not_to have_received(:save)
        end
      end
    end
  end
end
