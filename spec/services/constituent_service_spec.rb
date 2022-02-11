# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConstituentService do
  let(:virtual_object_content) do
    <<~XML
      <contentMetadata objectId="druid:virtual_object1" type="image">
        <resource sequence="1" id="wrongthing_1" type="image">
          <relationship type="alsoAvailableAs" objectId="druid:wrongthing"/>
        </resource>
      </contentMetadata>
    XML
  end

  let(:virtual_object) do
    Dor::Item.new(pid: 'druid:virtual_object1').tap do |item|
      item.contentMetadata.content = virtual_object_content
    end
  end

  let(:constituent1) do
    Dor::Item.new(pid: 'druid:constituent1').tap do |item|
      item.contentMetadata.content = <<~XML
        <contentMetadata>
          <resource id="bb000kg4251_1" sequence="1" type="image">
            <file id="bb000kg4251.jpg" mimetype="image/jpeg" size="1347965" preserve="yes" publish="no" shelve="no">
            </file>
          </resource>
        </contentMetadata>
      XML
    end
  end

  let(:constituent2) do
    Dor::Item.new(pid: 'druid:constituent2').tap do |item|
      item.contentMetadata.content = <<~XML
        <contentMetadata>
          <resource id="bb000ff1111_1" sequence="1" type="image">
            <file id="bb000ff1111.jpg" mimetype="image/jpeg" size="999" preserve="yes" publish="yes" shelve="no">
            </file>
          </resource>
        </contentMetadata>
      XML
    end
  end

  describe '#add' do
    subject(:add) { instance.add(constituent_druids: [constituent1.id, constituent2.id]) }

    let(:instance) do
      described_class.new(virtual_object_druid: virtual_object.id, event_factory: event_factory)
    end
    let(:event_factory) { class_double(EventFactory) }
    let(:namespaceless) { virtual_object.id.sub('druid:', '') }

    before do
      allow(virtual_object).to receive_messages(save!: true)
      allow(constituent1).to receive_messages(save!: true)
      allow(constituent2).to receive_messages(save!: true)

      # Used in ContentMetadataDS#add_virtual_resource
      allow(virtual_object.contentMetadata).to receive(:pid).and_return('druid:virtual_object1')

      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:virtual_object1').and_return(virtual_object)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:constituent1').and_return(constituent1)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:constituent2').and_return(constituent2)

      # Stub `#reset_metadata!` because ResetContentMetadataService is tested in its own spec
      allow(instance).to receive(:reset_metadata!)
    end

    context 'when the virtual_object is open for modification' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO) }

      before do
        allow(VersionService).to receive(:open?).and_return(true)
        allow(VersionService).to receive(:open)
        allow(VersionService).to receive(:close)
        allow(constituent1).to receive(:clear_relationship)
        allow(constituent2).to receive(:clear_relationship)
        allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
        add
      end

      it 'merges objects' do
        expect(instance).to have_received(:reset_metadata!).with(virtual_object).once
        expect(constituent1).to have_received(:clear_relationship).once
        expect(constituent2).to have_received(:clear_relationship).once
        expect(constituent1.object_relations[:is_constituent_of]).to eq [virtual_object]
        expect(constituent2.object_relations[:is_constituent_of]).to eq [virtual_object]
        expect(VersionService).to have_received(:open?).exactly(3).times
        expect(VersionService).not_to have_received(:open)
        expect(VersionService).to have_received(:close).with(anything,
                                                             {
                                                               description: described_class::VERSION_CLOSE_DESCRIPTION,
                                                               significance: described_class::VERSION_CLOSE_SIGNIFICANCE
                                                             },
                                                             event_factory: event_factory).exactly(3).times
      end
    end

    context 'when the virtual_object is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items)
          .with(virtual_object: virtual_object.id, constituents: [constituent1.id, constituent2.id])
          .and_return(virtual_object.id => ['that is a nope for constituent2'])
      end

      it 'merges nothing' do
        expect(add).to eq(virtual_object.id => ['that is a nope for constituent2'])
        expect(virtual_object.contentMetadata.content).to be_equivalent_to(virtual_object_content)
        expect(constituent1.object_relations[:is_constituent_of]).to be_empty
        expect(constituent2.object_relations[:is_constituent_of]).to be_empty
      end
    end

    context 'when a constituent is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items)
          .with(virtual_object: virtual_object.id, constituents: [constituent1.id, constituent2.id])
          .and_return(constituent1.id => 'not modifiable message')
      end

      it 'does not merge any constituents' do
        expect(add).to eq(constituent1.id => 'not modifiable message')
        expect(virtual_object.contentMetadata.content).to be_equivalent_to(virtual_object_content)
        expect(constituent1.object_relations[:is_constituent_of]).to be_empty
        expect(constituent2.object_relations[:is_constituent_of]).to be_empty
      end
    end
  end
end
