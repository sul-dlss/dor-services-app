# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::RightsMetadata do
  subject(:service) { described_class.new(Nokogiri::XML(original)) }

  describe '#create' do
    subject(:result) { service.create }

    context 'when no license node is present' do
      let(:original) do
        <<~XML
          <rightsMetadata>
            <use>
               <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
               <machine type="openDataCommons" uri="http://opendatacommons.org/licenses/by/1.0/">odc-by</machine>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'returns the original value' do
        expect(result).to be_equivalent_to(original)
      end
    end

    context 'when a open data commons license node is present' do
      let(:original) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>http://opendatacommons.org/licenses/by/1.0/</license>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>http://opendatacommons.org/licenses/by/1.0/</license>
               <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
               <machine type="openDataCommons" uri="http://opendatacommons.org/licenses/by/1.0/">odc-by</machine>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'adds the human and machine nodes' do
        expect(result).to be_equivalent_to(expected)
      end
    end

    context 'when a creativecommons license node is present' do
      let(:original) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>https://creativecommons.org/licenses/by-nd/4.0/</license>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>https://creativecommons.org/licenses/by-nd/4.0/</license>
               <human type="creativeCommons">Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)</human>
               <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-nd/4.0/">by-nd</machine>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'adds the human and machine nodes' do
        expect(result).to be_equivalent_to(expected)
      end
    end

    context 'when the "none" license is present' do
      let(:original) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>http://cocina.sul.stanford.edu/licenses/none</license>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <use>
               <license>http://cocina.sul.stanford.edu/licenses/none</license>
               <human type="creativeCommons">no Creative Commons (CC) license</human>
               <machine type="creativeCommons">none</machine>
               <human type="useAndReproduction">Whatever makes you happy</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'adds the human and machine nodes' do
        expect(result).to be_equivalent_to(expected)
      end
    end
  end
end
