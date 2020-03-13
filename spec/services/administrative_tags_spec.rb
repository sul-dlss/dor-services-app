# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTags do
  before do
    allow(item).to receive(:save!)
    described_class.create(item: item, tags: tags)
  end

  let(:item) { Dor::Item.new(pid: 'druid:aa123bb7890') }
  let(:tags) { ['Foo : Bar', 'Bar : Baz : Quux'] }

  describe '.for' do
    it 'returns the array of administrative tags' do
      expect(described_class.for(item: item)).to eq(tags)
    end
  end

  describe '.create' do
    it 'persists tags to identity metadata' do
      expect(item.identityMetadata.to_xml).to be_equivalent_to <<-XML
        <identityMetadata>
          <tag>Foo : Bar</tag>
          <tag>Bar : Baz : Quux</tag>
        </identityMetadata>
      XML
      expect(item).to have_received(:save!)
    end
  end
end
