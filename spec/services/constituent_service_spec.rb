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
      described_class.new(parent_druid: parent.id)
    end
    let(:namespaceless) { parent.id.sub('druid:', '') }
    let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

    before do
      allow(parent).to receive_messages(id: 'druid:parent1', save!: true)
      allow(child1).to receive_messages(id: 'druid:child1', save!: true)
      allow(child2).to receive_messages(id: 'druid:child2', save!: true)

      # Used in ContentMetadataDS#add_virtual_resource
      allow(parent.contentMetadata).to receive(:pid).and_return('druid:parent1')

      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:parent1').and_return(parent)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:child1').and_return(child1)
      allow(ItemQueryService).to receive(:find_combinable_item).with('druid:child2').and_return(child2)

      allow(Dor::Services::Client).to receive(:object).and_return(client)
    end

    context 'when the parent is open for modification' do
      before do
        add
      end

      it 'merges objects' do
        expect(parent.contentMetadata.content).to be_equivalent_to <<~XML
          <contentMetadata objectId="druid:parent1" type="image">
            <resource sequence="1" id="#{namespaceless}_1" type="image">
              <relationship type="alsoAvailableAs" objectId="#{child1.id}"/>
            </resource>
            <resource sequence="2" id="#{namespaceless}_2" type="image">
              <externalFile objectId="druid:child2" resourceId="bb000ff1111_1" fileId="bb000ff1111.jpg" mimetype="image/jpeg"/>
              <relationship type="alsoAvailableAs" objectId="#{child2.id}"/>
            </resource>
          </contentMetadata>
        XML
        expect(child1.object_relations[:is_constituent_of]).to eq [parent]
        expect(child2.object_relations[:is_constituent_of]).to eq [parent]
      end
    end

    context 'when the parent is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items).with([parent.id, child1.id, child2.id]).and_return(parent.id => 'nope')
      end

      it 'merges nothing' do
        expect(add).to eq(parent.id => 'nope')
        expect(parent.contentMetadata.content).to be_equivalent_to(parent_content)
        expect(child1.object_relations[:is_constituent_of]).to be_empty
        expect(child2.object_relations[:is_constituent_of]).to be_empty
      end
    end

    context 'when a child is not combinable' do
      before do
        allow(ItemQueryService).to receive(:validate_combinable_items).with([parent.id, child1.id, child2.id]).and_return(child1.id => 'not modifiable message')
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
