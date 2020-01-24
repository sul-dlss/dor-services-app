# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConstituentService do
  let(:parent_content) do
    <<~XML
      <contentMetadata objectId="druid:parent1" type="image">
        <resource sequence="1" id="wrongthing_1" type="image">
          <relationship type="alsoAvailableAs" objectId="druid:wrongthing"/>
        </resource>
      </contentMetadata>
    XML
  end

  let(:parent) do
    Dor::Item.new.tap do |item|
      item.contentMetadata.content = parent_content
    end
  end

  let(:child1) do
    Dor::Item.new.tap do |item|
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

  let(:child2) do
    Dor::Item.new.tap do |item|
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
    subject(:add) { instance.add(child_druids: [child1.id, child2.id]) }

    let(:instance) do
      described_class.new(parent_druid: parent.id, event_factory: event_factory)
    end
    let(:event_factory) { class_double(EventFactory) }
    let(:namespaceless) { parent.id.sub('druid:', '') }

    before do
      allow(parent).to receive_messages(id: 'druid:parent1', save!: true)
      allow(child1).to receive_messages(id: 'druid:child1', save!: true)
      allow(child2).to receive_messages(id: 'druid:child2', save!: true)

      # Used in ContentMetadataDS#add_virtual_resource
      allow(parent.contentMetadata).to receive(:pid).and_return('druid:parent1')

      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:parent1').and_return(parent)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:child1').and_return(child1)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:child2').and_return(child2)

      # Stub `#reset_metadata!` because ResetContentMetadataService is tested in its own spec
      allow(instance).to receive(:reset_metadata!)
    end

    context 'when the parent is open for modification' do
      before do
        allow(VersionService).to receive(:open?).and_return(true)
        allow(VersionService).to receive(:open)
        allow(VersionService).to receive(:close)
        allow(child1).to receive(:clear_relationship)
        allow(child2).to receive(:clear_relationship)
        add
      end

      it 'merges objects' do
        expect(instance).to have_received(:reset_metadata!).once
        expect(child1).to have_received(:clear_relationship).once
        expect(child2).to have_received(:clear_relationship).once
        expect(child1.object_relations[:is_constituent_of]).to eq [parent]
        expect(child2.object_relations[:is_constituent_of]).to eq [parent]
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

    context 'when the parent is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items).with(parent: parent.id, children: [child1.id, child2.id]).and_return(parent.id => ['that is a nope for child2'])
      end

      it 'merges nothing' do
        expect(add).to eq(parent.id => ['that is a nope for child2'])
        expect(parent.contentMetadata.content).to be_equivalent_to(parent_content)
        expect(child1.object_relations[:is_constituent_of]).to be_empty
        expect(child2.object_relations[:is_constituent_of]).to be_empty
      end
    end

    context 'when a child is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items).with(parent: parent.id, children: [child1.id, child2.id]).and_return(child1.id => 'not modifiable message')
      end

      it 'does not merge any children' do
        expect(add).to eq(child1.id => 'not modifiable message')
        expect(parent.contentMetadata.content).to be_equivalent_to(parent_content)
        expect(child1.object_relations[:is_constituent_of]).to be_empty
        expect(child2.object_relations[:is_constituent_of]).to be_empty
      end
    end
  end
end
