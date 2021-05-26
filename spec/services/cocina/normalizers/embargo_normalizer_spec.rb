# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::EmbargoNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(embargo_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when #normalize_empty' do
    let(:original_xml) do
      <<~XML
        <embargoMetadata>
          <status/>
          <releaseDate/>
          <releaseAccess/>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
        </embargoMetadata>
      XML
    end

    it 'removes empty elements' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
        XML
      )
    end
  end
end
