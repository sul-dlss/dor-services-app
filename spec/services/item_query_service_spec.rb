# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'bc123df4567' }
  let(:item) { instantiate_fixture('druid:bc123df4567', Dor::Item) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_routes: workflow_routes) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
  let(:workflows_response) do
    instance_double(Dor::Workflow::Response::Workflows, errors_for: errors)
  end
  let(:errors) { [] }

  before do
    allow(Dor::Item).to receive(:find).and_return(item)
    allow(VersionService).to receive(:can_open?).with(cocina_object).and_return(true)
    allow(VersionService).to receive(:open?).with(cocina_object).and_return(true)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Cocina::Mapper).to receive(:build).with(item).and_return(cocina_object)
  end

  describe '.find_combinable_item' do
    context 'when object has workflow errors' do
      let(:errors) { ['Net::ReadTimeout', 'Gremlins'] }

      it 'raises an error' do
        expect { service.find_combinable_item('bc123df4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:bc123df4567 has workflow errors: Net::ReadTimeout; Gremlins')
      end
    end

    it 'raises error if object is neither open nor openable' do
      allow(VersionService).to receive(:can_open?).with(cocina_object).and_return(false)
      allow(VersionService).to receive(:open?).with(cocina_object).and_return(false)
      expect { service.find_combinable_item('bc123df4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:bc123df4567 is not open or openable')
    end

    it 'raises error if object is dark' do
      dra = instance_double(Dor::RightsAuth, dark?: true, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      expect { service.find_combinable_item('bc123df4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:bc123df4567 is dark')
    end

    it 'raises error if object is citation_only' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: true)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      expect { service.find_combinable_item('bc123df4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:bc123df4567 is citation_only')
    end

    it 'returns item otherwise' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      service.find_combinable_item('bc123df4567')
    end
  end

  describe '.validate_combinable_items' do
    let(:item2) { instantiate_fixture('druid:xh235dd9059', Dor::Item) }
    let(:item3) { instantiate_fixture('druid:hj097bm8879', Dor::Item) }
    let(:cocina_object2) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:xh235dd9059') }
    let(:cocina_object3) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:hj097bm8879') }
    let(:dark_rights) { instance_double(Dor::RightsAuth, dark?: true, citation_only?: false) }
    let(:citation_only_rights) { instance_double(Dor::RightsAuth, dark?: false, citation_only?: true) }
    let(:permissive_rights) { instance_double(Dor::RightsAuth, dark?: false, citation_only?: false) }
    let(:dark_rights_ds) { instance_double(Dor::RightsMetadataDS, dra_object: dark_rights) }
    let(:citation_only_rights_ds) { instance_double(Dor::RightsMetadataDS, dra_object: citation_only_rights) }
    let(:permissive_rights_ds) { instance_double(Dor::RightsMetadataDS, dra_object: permissive_rights) }

    # Set defaults on all fixture objects and avoid making HTTP calls. Set defaults to the non-error cases.
    before do
      allow(Dor::Item).to receive(:find).with('druid:xh235dd9059').and_return(item2)
      allow(Dor::Item).to receive(:find).with('druid:hj097bm8879').and_return(item3)
      allow(VersionService).to receive(:can_open?).and_return(true)
      allow(VersionService).to receive(:open?).and_return(true)
      allow(Cocina::Mapper).to receive(:build).with(item2).and_return(cocina_object2)
      allow(Cocina::Mapper).to receive(:build).with(item3).and_return(cocina_object3)
      [item, item2, item3].each do |i|
        allow(i).to receive(:rightsMetadata).and_return(permissive_rights_ds)
      end
    end

    context 'when any objects have workflow errors' do
      let(:error_response) do
        instance_double(Dor::Workflow::Response::Workflows, errors_for: ['Boom'])
      end

      before do
        allow(workflow_routes).to receive(:all_workflows).with(pid: item.id).and_return(error_response)
      end

      it 'returns a single error' do
        expect(service.validate_combinable_items(virtual_object: 'druid:bc123df4567', constituents: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:bc123df4567' => ['Item druid:bc123df4567 has workflow errors: Boom']
        )
      end
    end

    context 'when any objects are both not open and not openable' do
      before do
        allow(VersionService).to receive(:open?).with(cocina_object).and_return(false)
        allow(VersionService).to receive(:can_open?).with(cocina_object).and_return(false)
      end

      it 'returns a single error if one object does not allow modification' do
        expect(service.validate_combinable_items(virtual_object: 'druid:bc123df4567', constituents: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:bc123df4567' => ['Item druid:bc123df4567 is not open or openable']
        )
      end
    end

    context 'when any objects are dark' do
      before do
        [item2, item3].each do |i|
          allow(i).to receive(:rightsMetadata).and_return(dark_rights_ds)
        end
      end

      it 'returns errors if any objects are dark' do
        expect(service.validate_combinable_items(virtual_object: 'druid:bc123df4567', constituents: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:bc123df4567' => ['Item druid:xh235dd9059 is dark', 'Item druid:hj097bm8879 is dark']
        )
      end
    end

    context 'when any objects are citation-only' do
      before do
        [item, item3].each do |i|
          allow(i).to receive(:rightsMetadata).and_return(citation_only_rights_ds)
        end
      end

      it 'raises error if any objects are citation_only' do
        expect(service.validate_combinable_items(virtual_object: 'druid:bc123df4567', constituents: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:bc123df4567' => ['Item druid:bc123df4567 is citation_only', 'Item druid:hj097bm8879 is citation_only']
        )
      end
    end

    context 'when none of the error conditions exist' do
      before do
        [item, item2, item3].each do |i|
          allow(i).to receive(:rightsMetadata).and_return(permissive_rights_ds)
        end
      end

      it 'returns an empty hash otherwise' do
        expect(service.validate_combinable_items(virtual_object: 'druid:bc123df4567', constituents: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq({})
      end
    end
  end
end
