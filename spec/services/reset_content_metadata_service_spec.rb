# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetContentMetadataService do
  subject(:service) { described_class.new(args) }

  let(:args) { { item: parent } }
  let(:child1) do
    instance_double(Dor::Item,
                    id: 'druid:child1',
                    relationships_are_dirty?: true,
                    save!: true,
                    clear_relationship: nil)
  end
  let(:child2) do
    instance_double(Dor::Item,
                    id: 'druid:child2',
                    relationships_are_dirty?: true,
                    save!: true,
                    clear_relationship: nil)
  end
  let(:content_metadata) do
    instance_double(Dor::ContentMetadataDS,
                    ng_xml: xml,
                    'content=': nil)
  end
  let(:default_content_xml) { "<contentMetadata objectId='druid:parent' type='image'/>" }
  let(:parent) do
    instance_double(Dor::Item,
                    id: 'druid:parent',
                    contentMetadata: content_metadata,
                    save!: true)
  end
  let(:predicate) { :is_constituent_of }

  describe '.new' do
    let(:xml) { '<notUsed/>' }

    context 'when only the `item:` argument is included' do
      it 'uses the supplied `item` attribute' do
        expect(service.item).to eq(parent)
      end

      it 'uses the default `type` attribute' do
        expect(service.type).to eq(described_class::DEFAULT_ITEM_TYPE)
      end
    end

    context 'when `item:` and `type:` arguments are included' do
      let(:args) { { item: parent, type: custom_type } }
      let(:custom_type) { 'book' }

      it 'uses the supplied `type` attribute' do
        expect(service.type).to eq(custom_type)
      end
    end
  end

  describe '#reset' do
    context 'without child relationships recorded in content metadata' do
      let(:xml) { Nokogiri::XML(default_content_xml) }

      before do
        allow(Dor::Item).to receive(:find)
      end

      it 'resets content metadata without touching children' do
        service.reset
        expect(content_metadata).to have_received(:content=).with(default_content_xml).once
        expect(parent).to have_received(:save!).once
        expect(Dor::Item).not_to have_received(:find)
      end
    end

    context 'with child relationships recorded in content metadata' do
      let(:xml) do
        Nokogiri::XML(
          <<~XML
            <contentMetadata objectId="druid:parent1" type="image">
              <resource sequence="1" id="druid:child1_1" type="image">
                <relationship type="alsoAvailableAs" objectId="druid:child1"/>
              </resource>
              <resource sequence="2" id="druid:child2_2" type="image">
                <relationship type="alsoAvailableAs" objectId="druid:child2"/>
              </resource>
            </contentMetadata>
          XML
        )
      end

      before do
        allow(Dor::Item).to receive(:find).with(child1.id).and_return(child1)
        allow(Dor::Item).to receive(:find).with(child2.id).and_return(child2)
      end

      it 'severs the child relationships and resets content metadata' do
        service.reset
        expect(content_metadata).to have_received(:content=).with(default_content_xml).once
        expect(parent).to have_received(:save!).once
        expect(Dor::Item).to have_received(:find).exactly(2).times
        expect(child1).to have_received(:clear_relationship).with(predicate).once
        expect(child2).to have_received(:clear_relationship).with(predicate).once
        expect(child1).to have_received(:save!)
        expect(child2).to have_received(:save!)
      end
    end
  end
end
