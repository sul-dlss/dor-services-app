# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::EmbargoNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(embargo_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when released embargo' do
    let(:original_xml) do
      <<~XML
        <embargoMetadata>
          <status>released</status>
          <releaseDate>2018-06-02T07:00:00Z</releaseDate>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
          <releaseAccess>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
          </releaseAccess>
        </embargoMetadata>
      XML
    end

    it 'removes embargo (removes all XML nodes)' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
        XML
      )
    end
  end

  context 'when non-released embargo' do
    # adapted from bw190bf2187
    let(:original_xml) do
      <<~XML
         <embargoMetadata>
          <status>embargoed</status>
          <releaseDate>2022-05-06T00:00:00Z</releaseDate>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
          <releaseAccess>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
          </releaseAccess>
        </embargoMetadata>
      XML
    end

    it 'retains the releaseAccess node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <embargoMetadata>
            <status>embargoed</status>
            <releaseDate>2022-05-06T00:00:00Z</releaseDate>
            <releaseAccess>
              <access type="discover">
                <machine>
                  <world/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </releaseAccess>
          </embargoMetadata>
        XML
      )
    end
  end

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

  context 'when #normalize_empty with values' do
    let(:original_xml) do
      <<~XML
        <embargoMetadata>
          <releaseDate>2021-06-02T07:00:00Z</releaseDate>
          <releaseAccess/>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
        </embargoMetadata>
      XML
    end

    it 'only removes empty elements' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <embargoMetadata>
            <releaseDate>2021-06-02T07:00:00Z</releaseDate>
          </embargoMetadata>
        XML
      )
    end
  end
end
