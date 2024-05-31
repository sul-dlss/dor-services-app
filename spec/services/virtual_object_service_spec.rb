# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualObjectService do
  describe '#constituents' do
    let(:constituents) { described_class.constituents(cocina_object, only_published:, exclude_opened:).sort }
    let(:only_published) { false }
    let(:exclude_opened) { false }

    context 'when the virtual object is a DRO' do
      let(:cocina_object) do
        build(:dro).new(structural: {
                          contains: [],
                          hasMemberOrders: [
                            {
                              members: [
                                'druid:dj321gm8879', # published and closed
                                'druid:vs491yc7072', # published and open
                                'druid:bc778pm9866' # unpublished and closed
                              ],
                              viewingDirection: 'left-to-right'
                            }
                          ],
                          isMemberOf: []
                        })
      end

      before do
        create(:repository_object, :closed, external_identifier: 'druid:dj321gm8879')
        create(:repository_object, external_identifier: 'druid:vs491yc7072')
        create(:repository_object, :closed, external_identifier: 'druid:bc778pm9866')
        allow(WorkflowStateService).to receive(:published?).with(druid: 'druid:dj321gm8879', version: 1).and_return(true)
        allow(WorkflowStateService).to receive(:published?).with(druid: 'druid:vs491yc7072', version: 1).and_return(true)
        allow(WorkflowStateService).to receive(:published?).with(druid: 'druid:bc778pm9866', version: 1).and_return(false)
      end

      context 'when not limited' do
        it 'returns the druids of the constituent objects' do
          expect(constituents).to eq(['druid:bc778pm9866', 'druid:dj321gm8879', 'druid:vs491yc7072'])
        end
      end

      context 'when only published' do
        let(:only_published) { true }

        it 'returns the druids of the constituent objects' do
          expect(constituents).to eq(['druid:dj321gm8879', 'druid:vs491yc7072'])
        end
      end

      context 'when only closed' do
        let(:exclude_opened) { true }

        it 'returns the druids of the constituent objects' do
          expect(constituents).to eq(['druid:bc778pm9866', 'druid:dj321gm8879'])
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
