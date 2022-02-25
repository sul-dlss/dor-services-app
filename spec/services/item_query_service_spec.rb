# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'druid:bc123df4567' }
  let(:access) { { access: 'world' } }
  let(:cocina_object) do
    Cocina::Models::DRO.new(
      externalIdentifier: druid,
      version: 1,
      type: Cocina::Models::Vocab.object,
      label: 'Dummy DRO',
      access: { download: 'none' }.merge(access),
      administrative: { hasAdminPolicy: 'druid:df123cd4567' }
    )
  end
  let(:workflow_state) { 'Accessioned' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: status_client) }
  let(:status_client) { instance_double(Dor::Workflow::Client::Status, display_simplified: workflow_state) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.find_combinable_item' do
    context 'with item in accessioned state' do
      let(:workflow_state) { 'Accessioned' }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end

    context 'with item in opened state' do
      let(:workflow_state) { 'Opened' }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
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
      let(:access) { { access: 'dark' } }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is dark"
        )
      end
    end

    context 'with citation-only item' do
      let(:access) { { access: 'citation-only' } }

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is citation-only"
        )
      end
    end

    context 'with world-accessible item' do
      let(:access) { { access: 'world' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end

    context 'with stanford-accessible item' do
      let(:access) { { access: 'stanford', download: 'stanford' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end

    context 'with location-based item' do
      let(:access) { { access: 'location-based', readLocation: 'music' } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end

    context 'with CDL item' do
      let(:access) { { access: 'stanford', controlledDigitalLending: true } }

      it 'returns the item' do
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end

    context 'with a collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(
          externalIdentifier: druid,
          version: 1,
          type: Cocina::Models::Vocab.collection,
          label: 'Dummy DRO',
          access: access,
          administrative: { hasAdminPolicy: 'druid:df123cd4567' }
        )
      end

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not an item"
        )
      end
    end

    context 'with an admin policy' do
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new(
          externalIdentifier: druid,
          version: 1,
          type: Cocina::Models::Vocab.admin_policy,
          label: 'Dummy DRO',
          administrative: { hasAdminPolicy: 'druid:df123cd4567', hasAgreement: 'druid:mg978jy9754' }
        )
      end

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is not an item"
        )
      end
    end

    context 'with an virtual object' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(
          externalIdentifier: druid,
          version: 1,
          type: Cocina::Models::Vocab.object,
          label: 'Dummy DRO',
          access: { download: 'none' }.merge(access),
          administrative: { hasAdminPolicy: 'druid:df123cd4567' },
          structural: {
            hasMemberOrders: [
              {
                members: ['druid:df123cd4567', 'druid:mg978jy9754']
              }
            ]
          }
        )
      end

      it 'raises an error' do
        expect { service.find_combinable_item(druid) }.to raise_error(
          described_class::UncombinableItemError,
          "Item #{druid} is itself a virtual object"
        )
      end
    end

    context 'with an DRO having memberless member orders' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(
          externalIdentifier: druid,
          version: 1,
          type: Cocina::Models::Vocab.object,
          label: 'Dummy DRO',
          access: { download: 'none' }.merge(access),
          administrative: { hasAdminPolicy: 'druid:df123cd4567' },
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
        expect(service.find_combinable_item(druid)).to eq(cocina_object)
      end
    end
  end

  describe '.validate_combinable_items' do
    let(:constituent_druids) { ['druid:xh235dd9059'] }

    context 'when any items are uncombinable' do
      before do
        allow(described_class).to receive(:find_combinable_item)
        allow(described_class).to receive(:find_combinable_item).with(druid).and_raise(described_class::UncombinableItemError, "Item #{druid} is dark")
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
      end

      it 'returns an empty hash otherwise' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq({})
      end
    end

    context 'when constituents include the virtual object' do
      let(:constituent_druids) { ['druid:xh235dd9059', druid] }

      before do
        allow(described_class).to receive(:find_combinable_item)
      end

      it 'returns an error' do
        expect(service.validate_combinable_items(virtual_object: druid, constituents: constituent_druids)).to eq(
          druid => ['Item druid:bc123df4567 cannot be a constituent of itself']
        )
      end
    end
  end
end
