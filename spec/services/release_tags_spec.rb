# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  before do
    described_class.create(work, release: true, what: 'self', when: '2018-11-30T22:41:35Z', to: 'SearchWorks')
  end

  let(:druid) { 'druid:aa123bb7890' }
  let(:work) { Dor::Item.new(pid: druid) }

  describe '.legacy_for' do
    it 'returns the hash of release tags' do
      expect(described_class.legacy_for(item: work)).to eq(
        'SearchWorks' => {
          'release' => true
        }
      )
    end
  end

  describe '.for' do
    let(:dro_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

    before do
      allow(Dor).to receive(:find).and_return(work)
    end

    it 'returns the hash of release tags' do
      expect(described_class.for(dro_object: dro_object)).to eq(
        'SearchWorks' => {
          'release' => true
        }
      )
      expect(Dor).to have_received(:find).with(druid)
    end
  end

  describe '.create' do
    it 'creates a plain directory in the workspace when passed no source directory' do
      expect(work.identityMetadata.to_xml).to be_equivalent_to <<-XML
        <identityMetadata>
          <release what="self" when="2018-11-30T22:41:35Z" to="SearchWorks">true</release>
        </identityMetadata>
      XML
    end
  end
end
