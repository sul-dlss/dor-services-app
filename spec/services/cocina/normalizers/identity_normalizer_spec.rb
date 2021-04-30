# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::IdentityNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(identity_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when normalizing sourceId' do
    let(:original_xml) do
      <<~XML
        <identityMetadata>
           <sourceId source=" sul "> M0443_S2_D-K_B9_F33_011 </sourceId>
        </identityMetadata>
      XML
    end

    it 'removes spaces' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <identityMetadata>
             <sourceId source="sul">M0443_S2_D-K_B9_F33_011</sourceId>
          </identityMetadata>
        XML
      )
    end
  end
end
