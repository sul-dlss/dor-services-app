# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemQueryService do
  subject(:service) { described_class }

  let(:druid) { 'ab123cd4567' }
  let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Item) }

  before do
    allow(Dor::Item).to receive(:find).and_return(item)
  end

  describe '.find_combinable_item' do
    it 'raises error if object does not allow modification' do
      allow(item).to receive(:allows_modification?).and_return(false)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(RuntimeError, 'Item druid:ab123cd4567 is not open for modification')
    end
    it 'raises error if object is dark' do
      dra = instance_double(Dor::RightsAuth, dark?: true, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      allow(item).to receive(:allows_modification?).and_return(true)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(RuntimeError, 'Item druid:ab123cd4567 is dark')
    end
    it 'raises error if object is citation_only' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: true)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      allow(item).to receive(:allows_modification?).and_return(true)
      expect { service.find_combinable_item('ab123cd4567') }.to raise_error(RuntimeError, 'Item druid:ab123cd4567 is citation_only')
    end
    it 'returns item otherwise' do
      dra = instance_double(Dor::RightsAuth, dark?: false, citation_only?: false)
      rights_ds = instance_double(Dor::RightsMetadataDS, dra_object: dra)
      allow(item).to receive(:rightsMetadata).and_return(rights_ds)
      allow(item).to receive(:allows_modification?).and_return(true)
      service.find_combinable_item('ab123cd4567')
    end
  end

  describe '.find_modifiable_item' do
    it 'raises error if object does not allow modification' do
      allow(item).to receive(:allows_modification?).and_return(false)
      expect { service.find_modifiable_item('ab123cd4567') }.to raise_error(RuntimeError, 'Item druid:ab123cd4567 is not open for modification')
    end
    it 'returns item if it is modifiable' do
      allow(item).to receive(:allows_modification?).and_return(true)
      service.find_modifiable_item('ab123cd4567')
    end
  end
end
