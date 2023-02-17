# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateMarcRecordService do
  subject(:umrs) { described_class.new(cocina_object, thumbnail_service:) }

  let(:druid) { 'druid:bc123dg9393' }
  let(:thumbnail_service) { ThumbnailService.new(cocina_object) }
  let(:cocina_object) { build(:dro, id: druid) }

  describe '.update' do
    before do
      allow(described_class).to receive(:new).and_return(umrs)
      allow(umrs).to receive(:update)
    end

    it 'invokes #update on a new instance' do
      described_class.update(cocina_object, thumbnail_service:)
      expect(umrs).to have_received(:update).once
    end
  end

  describe '#update' do
    before do
      allow(MarcGenerator).to receive(:create).and_return(marc_records)
      allow(SymphonyWriter).to receive(:save)
      umrs.update
    end

    context 'when there are marc records' do
      let(:marc_records) { ['abcd1244', 'def5678'] }

      it 'calls symphony_writer' do
        expect(SymphonyWriter).to have_received(:save).with(marc_records)
      end
    end

    context 'when there are no marc records' do
      let(:marc_records) { [] }

      it 'does not call symphony_writer' do
        expect(SymphonyWriter).not_to have_received(:save)
      end
    end
  end
end
