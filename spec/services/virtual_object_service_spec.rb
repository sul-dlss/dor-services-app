# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualObjectService do
  describe '#constituents' do
    let(:constituents) { described_class.constituents(cocina_object, publishable:).sort }
    let(:publishable) { false }

    context 'when the virtual object is a DRO' do
      let(:cocina_object) do
        build(:dro).new(structural: {
                          contains: [],
                          hasMemberOrders: [
                            {
                              members: [
                                'druid:dj321gm8879', # has a closed version with cocina, thus publishable
                                'druid:vs491yc7072', # has a closed version without cocina, thus not publishable
                                'druid:bc778pm9866' # lacks a closed version, thus not publishable
                              ],
                              viewingDirection: 'left-to-right'
                            }
                          ],
                          isMemberOf: []
                        })
      end

      before do
        create(:repository_object, :closed, external_identifier: 'druid:dj321gm8879').tap do |object|
          object.last_closed_version.update!(cocina_version: 1)
        end
        create(:repository_object, :closed, external_identifier: 'druid:vs491yc7072')
        create(:repository_object, external_identifier: 'druid:bc778pm9866')
      end

      context 'when not limited' do
        it 'returns the druids of the constituent objects' do
          expect(constituents).to eq(['druid:bc778pm9866', 'druid:dj321gm8879', 'druid:vs491yc7072'])
        end
      end

      context 'when limited to publishable constituents' do
        let(:publishable) { true }

        it 'returns the druids of the constituent objects that are publishable' do
          expect(constituents).to eq(['druid:dj321gm8879'])
        end
      end
    end

    context 'when the virtual object is a collection' do
      let(:cocina_object) { build(:collection) }

      it 'returns an empty array' do
        expect(constituents).to eq([])
      end
    end
  end
end
