# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  describe '.create' do
    before do
      allow(Dor::SuriService).to receive(:mint_id).and_return('druid:aa123bb7890')
    end

    let(:work) { Dor::Item.new }

    it 'creates a plain directory in the workspace when passed no source directory' do
      described_class.create(work, release: true, what: 'self', when: '2018-11-30T22:41:35Z')
      expect(work.identityMetadata.to_xml).to be_equivalent_to <<-XML
        <identityMetadata>
          <release what="self" when="2018-11-30T22:41:35Z">true</release>
        </identityMetadata>
      XML
    end
  end
end
