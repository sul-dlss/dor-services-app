# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'druid:bc123df4567' }
  let(:access) { { view: 'world' } }
  let(:cocina_object) do
    build(:dro, id: druid).new(access: { download: 'none' }.merge(access))
  end
  let(:created_at) { Time.zone.now }
  let(:updated_at) { Time.zone.now }
  let(:cocina_object_with_metadata) do
    Cocina::Models.with_metadata(cocina_object, '1', created: created_at, modified: updated_at)
  end

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object_with_metadata)
    allow(VersionService).to receive(:open?).and_return(true)
    allow(Workflow::StateService).to receive(:accessioned?).and_return(true)
  end

  describe '.find_combinable_item' do
    context 'with dark item' do
      let(:access) { { view: 'dark' } }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is dark"
        )
      end
    end

    context 'with citation-only item' do
      let(:access) { { view: 'citation-only' } }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is citation-only"
        )
      end
    end

    context 'with world-accessible item' do
      let(:access) { { view: 'world' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with stanford-accessible item' do
      let(:access) { { view: 'stanford', download: 'stanford' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with location-based item' do
      let(:access) { { view: 'location-based', location: 'music' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with CDL item' do
      let(:access) { { view: 'stanford', controlledDigitalLending: true } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with a collection' do
      let(:cocina_object) do
        build(:collection, id: druid).new(access:)
      end

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not an item"
        )
      end
    end

    context 'with an admin policy' do
      let(:cocina_object) { build(:admin_policy, id: druid) }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not an item"
        )
      end
    end

    context 'with an DRO having memberless member orders' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          access: { download: 'none' }.merge(access),
          structural: {
            hasMemberOrders: [
              {
                viewingDirection: 'left-to-right'
              }
            ]
          }
        )
      end

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end
  end

  describe '.validate_combinable_items' do
    let(:constituent_druids) { ['druid:xh235dd9059'] }

    context 'when any items are uncombinable' do
      before do
        allow(described_class).to receive(:find_combinable_item)
        allow(described_class).to receive(:find_combinable_item).with(druid).and_raise(
          described_class::UncombinableItemError, "Item #{druid} is dark"
        )
        allow(described_class).to receive(:check_virtual)
        allow(described_class).to receive(:check_accessioned)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          'druid:bc123df4567' => ['Item druid:bc123df4567 is dark']
        )
        expect(described_class).to have_received(:check_virtual).with('druid:xh235dd9059')
      end
    end

    context 'when all items are combinable' do
      before do
        allow(described_class).to receive(:find_combinable_item)
        allow(described_class).to receive(:check_virtual)
        allow(described_class).to receive(:check_accessioned)
      end

      it 'returns an empty hash otherwise' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq({})
      end
    end

    context 'when constituents include the virtual object' do
      let(:constituent_druids) { ['druid:xh235dd9059', druid] }

      before do
        allow(described_class).to receive(:find_combinable_item)
        allow(described_class).to receive(:check_virtual)
        allow(described_class).to receive(:check_accessioned)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          druid => ['Item druid:bc123df4567 cannot be a constituent of itself']
        )
      end
    end

    context 'when multiple constituents are uncombinable' do
      let(:constituent_druids) { ['druid:cc111dd2222', 'druid:bb111cc2222'] }
      let(:cocina_object_constituent) do
        build(:dro, id: constituent_druids[0]).new(
          access: { view: 'citation-only', download: 'none' }
        )
      end
      let(:cocina_object_constituent_with_metadata) do
        Cocina::Models.with_metadata(cocina_object_constituent, '1', created: created_at, modified: updated_at)
      end

      let(:cocina_object_constituent1) do
        build(:dro, id: constituent_druids[1]).new(
          access: { view: 'dark' }
        )
      end
      let(:cocina_object_constituent1_with_metadata) do
        Cocina::Models.with_metadata(cocina_object_constituent1, '1', created: created_at, modified: updated_at)
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with(constituent_druids[0])
                                                  .and_return(cocina_object_constituent_with_metadata)
        allow(CocinaObjectStore).to receive(:find).with(constituent_druids[1])
                                                  .and_return(cocina_object_constituent1_with_metadata)
        allow(described_class).to receive(:check_virtual)
      end

      it 'adds both error messages to the errors hash' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          'druid:bc123df4567' => ['Item druid:cc111dd2222 is citation-only', 'Item druid:bb111cc2222 is dark']
        )
      end
    end
  end

  describe '.check_virtual' do
    context 'when a constituent is virtual_object' do
      let(:constituent_druid) { 'druid:xh235dd9059' }
      let(:constituent_druids) { [constituent_druid] }
      let(:cocina_object_constituent) do
        build(:dro, id: constituent_druid).new(
          access: { download: 'world' }.merge(access),
          structural: {
            hasMemberOrders: [
              {
                members: ['druid:bj876jy8756']
              },
              {
                members: ['druid:bj776jy8755']
              }
            ]
          }
        )
      end
      let(:cocina_object_constituent_with_metadata) do
        Cocina::Models.with_metadata(cocina_object_constituent, '1', created: created_at, modified: updated_at)
      end

      before do
        allow(CocinaObjectStore).to receive(:find)
          .with(constituent_druid).and_return(cocina_object_constituent_with_metadata)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          druid => ["Item #{constituent_druid} is itself a virtual object"]
        )
      end
    end
  end

  describe '.check_open' do
    context 'with item in opened state' do
      before do
        allow(VersionService).to receive_messages(open?: true, can_open?: false)
      end

      it 'returns the item' do
        expect(service.check_open(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with item in openable state' do
      before do
        allow(VersionService).to receive_messages(open?: false, can_open?: true)
      end

      it 'returns the item' do
        expect(service.check_open(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with item not in open state or openable' do
      before do
        allow(VersionService).to receive_messages(open?: false, can_open?: false)
      end

      it 'raises an error' do
        expect { service.check_open(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not open or openable"
        )
      end
    end
  end

  describe '.check_accessioned' do
    context 'when item has been accessioned' do
      before do
        allow(Workflow::StateService).to receive(:accessioned?).and_return(true)
      end

      it 'raises an error' do
        expect { service.check_accessioned(druid) }.not_to raise_error
      end
    end

    context 'when item has not been accessioned' do
      before do
        allow(Workflow::StateService).to receive(:accessioned?).and_return(false)
      end

      it 'raises an error' do
        expect { service.check_accessioned(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} has not been accessioned"
        )
      end
    end
  end
end
