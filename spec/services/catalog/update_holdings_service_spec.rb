# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::UpdateHoldingsService do
  subject(:update_holdings_service) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:dro).new(identification: identification) }
  let(:identification) do
    {
      sourceId: 'sul:8832162',
      catalogLinks: [
        {
          catalog: 'folio',
          catalogRecordId: 'a123'
        }
      ]
    }
  end

  before do
    allow(Catalog::HoldingsGenerator).to receive(:manage_holdings)
  end

  describe '.update' do
    it 'calls manage_holdings on a new instance of HoldingsGenerator' do
      described_class.update(cocina_object)

      expect(Catalog::HoldingsGenerator).to have_received(:manage_holdings).with(cocina_object)
    end
  end

  describe '#update' do
    context 'when the object is an admin policy' do
      let(:cocina_object) { build(:admin_policy) }

      it 'does not call manage_holdings' do
        described_class.update(cocina_object)

        expect(Catalog::HoldingsGenerator).not_to have_received(:manage_holdings)
      end
    end

    context 'when the object does not have a FOLIO catalog link' do
      let(:cocina_object) do
        build(:dro).new(identification: {
                          sourceId: 'sul:8832162',
                          catalogLinks: []
                        })
      end

      it 'does not call manage_holdings' do
        described_class.update(cocina_object)

        expect(Catalog::HoldingsGenerator).not_to have_received(:manage_holdings)
      end
    end
  end
end
