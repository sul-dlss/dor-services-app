# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'ab123cd4567' }
  let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Item) }

  before do
    allow(Dor::Item).to receive(:find).and_return(item)
    allow(VersionService).to receive(:can_open?).with(item).and_return(true)
    allow(VersionService).to receive(:open?).with(item).and_return(true)
  end

  describe '.find_combinable_item' do
    it 'raises error if object is neither open nor openable' do
      allow(VersionService).to receive(:can_open?).with(item).and_return(false)
      allow(VersionService).to receive(:open?).with(item).and_return(false)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:ab123cd4567 is not open or openable')
    end

    it 'raises error if object is dark' do
      dra = instance_double(Dor::RightsAuth, dark?: true, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:ab123cd4567 is dark')
    end

    it 'raises error if object is citation_only' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: true)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(described_class::UncombinableItemError, 'Item druid:ab123cd4567 is citation_only')
    end

    it 'returns item otherwise' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      service.find_combinable_item('ab123cd4567')
    end
  end

  describe '.validate_combinable_items' do
    let(:item2) { instantiate_fixture('druid:xh235dd9059', Dor::Item) }
    let(:item3) { instantiate_fixture('druid:hj097bm8879', Dor::Item) }
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
      [item, item2, item3].each do |i|
        allow(i).to receive(:rightsMetadata).and_return(permissive_rights_ds)
        allow(VersionService).to receive(:can_open?).with(i).and_return(true)
        allow(VersionService).to receive(:open?).with(i).and_return(true)
      end
    end

    context 'when any objects are both not open and not openable' do
      before do
        allow(VersionService).to receive(:open?).with(item).and_return(false)
        allow(VersionService).to receive(:can_open?).with(item).and_return(false)
      end

      it 'returns a single error if one object does not allow modification' do
        expect(service.validate_combinable_items(parent: 'druid:ab123cd4567', children: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:ab123cd4567' => ['Item druid:ab123cd4567 is not open or openable']
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
        expect(service.validate_combinable_items(parent: 'druid:ab123cd4567', children: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:ab123cd4567' => ['Item druid:xh235dd9059 is dark', 'Item druid:hj097bm8879 is dark']
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
        expect(service.validate_combinable_items(parent: 'druid:ab123cd4567', children: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq(
          'druid:ab123cd4567' => ['Item druid:ab123cd4567 is citation_only', 'Item druid:hj097bm8879 is citation_only']
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
        expect(service.validate_combinable_items(parent: 'druid:ab123cd4567', children: ['druid:xh235dd9059', 'druid:hj097bm8879'])).to eq({})
      end
    end
  end
end
