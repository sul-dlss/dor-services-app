# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  before do
    # allow(Dor::SuriService).to receive(:mint_id).and_return('druid:aa123bb7890')
    described_class.create(work, release: true, what: 'self', when: '2018-11-30T22:41:35Z', to: 'SearchWorks')
  end

  let(:work) { Dor::Item.new(pid: 'druid:aa123bb7890') }

  describe '.for' do
    it 'returns the hash of release tags' do
      expect(described_class.for(item: work)).to eq(
        'SearchWorks' => {
          'release' => true
        }
      )
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
