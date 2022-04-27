# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'druid:bc123df4567' }
  let(:access) { { view: 'world' } }
  let(:cocina_object) do
    build(:dro, id: druid).new(access: { download: 'none' }.merge(access))
  end
  let(:workflow_state) { 'Accessioned' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: status_client) }
  let(:status_client) { instance_double(Dor::Workflow::Client::Status, display_simplified: workflow_state) }
  let(:created_at) { Time.zone.now }
  let(:updated_at) { Time.zone.now }
  let(:cocina_object_with_metadata) { Cocina::Models.with_metadata(cocina_object, '1', created: created_at, modified: updated_at) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object_with_metadata)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.find_combinable_item' do
    context 'with item in accessioned state' do
      let(:workflow_state) { 'Accessioned' }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with item in opened state' do
      let(:workflow_state) { 'Opened' }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to match_cocina_object_with(cocina_object.to_h)
      end
    end

    context 'with item in registered state' do
      let(:workflow_state) { 'Registered' }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not in the accessioned or opened workflow state"
        )
      end
    end

    context 'with item in accessioning state' do
      let(:workflow_state) { 'In Accessioning' }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not in the accessioned or opened workflow state"
        )
      end
    end

    context 'with item in unknown state' do
      let(:workflow_state) { 'Unknown Status' }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not in the accessioned or opened workflow state"
        )
      end
    end

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
        build(:collection, id: druid).new(access: access)
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
        allow(described_class).to receive(:find_combinable_item).with(druid).and_raise(described_class::UncombinableItemError, "Item #{druid} is dark")
        allow(described_class).to receive(:check_virtual)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          'druid:bc123df4567' => ['Item druid:bc123df4567 is dark']
        )
      end
    end

    context 'when all items are combinable' do
      before do
        allow(described_class).to receive(:find_combinable_item)
        allow(described_class).to receive(:check_virtual)
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
      let(:cocina_object_constituent_with_metadata) { Cocina::Models.with_metadata(cocina_object_constituent, '1', created: created_at, modified: updated_at) }

      let(:cocina_object_constituent1) do
        build(:dro, id: constituent_druids[1]).new(
          access: { view: 'dark' }
        )
      end
      let(:cocina_object_constituent1_with_metadata) { Cocina::Models.with_metadata(cocina_object_constituent1, '1', created: created_at, modified: updated_at) }

      before do
        allow(CocinaObjectStore).to receive(:find).with(constituent_druids[0]).and_return(cocina_object_constituent_with_metadata)
        allow(CocinaObjectStore).to receive(:find).with(constituent_druids[1]).and_return(cocina_object_constituent1_with_metadata)
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
      let(:cocina_object_constituent_with_metadata) { Cocina::Models.with_metadata(cocina_object_constituent, '1', created: created_at, modified: updated_at) }

      before do
        allow(CocinaObjectStore).to receive(:find).with(constituent_druid).and_return(cocina_object_constituent_with_metadata)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          druid => ["Item #{constituent_druid} is itself a virtual object"]
        )
      end
    end
  end
end
