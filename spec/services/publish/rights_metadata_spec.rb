# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::RightsMetadata do
  subject(:service) { described_class.new(Nokogiri::XML(original), release_date: release_date) }

  let(:release_date) { nil }

  describe '#create' do
    subject(:result) { service.create }

    context 'when an embargo date is provided' do
      let(:release_date) { '2020-02-26T00:00:00Z' }

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
                <embargoReleaseDate>2020-02-26T00:00:00Z</embargoReleaseDate>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      context 'without an existing embargoReleaseDate node' do
        let(:original) do
          <<~XML
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <world />
                </machine>
              </access>
              <access type="read">
                <machine>
                  <group>stanford</group>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        it 'adds the embargo release date' do
          expect(result).to be_equivalent_to(expected)
        end
      end

      context 'with an existing embargoReleaseDate node' do
        let(:original) do
          <<~XML
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <world />
                </machine>
              </access>
              <access type="read">
                <machine>
                  <embargoReleaseDate>2025-11-11T00:00:00Z</embargoReleaseDate>
                  <group>stanford</group>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        it 'adds the embargo release date' do
          expect(result).to be_equivalent_to(expected)
        end
      end
    end

    context 'when no license node is present' do
      let(:original) do
        <<~XML
          <rightsMetadata>
            <use>
               <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
               <machine type="openDataCommons" uri="https://opendatacommons.org/licenses/by/1-0/">odc-by</machine>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'returns the original value' do
        expect(result).to be_equivalent_to(original)
      end
    end
  end
end
