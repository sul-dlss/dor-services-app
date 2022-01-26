# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::AdminNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(admin_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when #normalize_desc_metadata_nodes' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <registration>
            <workflow id="goobiWF"/>
            <collection id="druid:fm742nb7315"/>
          </registration>
          <dissemination>
            <workflow id="someNotEmptyValue"/>
          </dissemination>
          <descMetadata>
            <format>MODS</format>
            <source>Symphony</source>
           </descMetadata>
        </administrativeMetadata>
      XML
    end

    it 'removes unncessary descMetadata node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="goobiWF"/>
              <collection id="druid:fm742nb7315"/>
            </registration>
            <dissemination>
              <workflow id="someNotEmptyValue"/>
            </dissemination>
          </administrativeMetadata>
        XML
      )
    end

    context 'when #normalize_empty_registration_and_dissemination' do
      let(:original_xml) do
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="goobiWF"/>
              <collection id="druid:fm742nb7315"/>
            </registration>
            <dissemination>
              <workflow id="someNotEmptyValue"/>
            </dissemination>
            <registration />
            <dissemination />
          </administrativeMetadata>
        XML
      end

      it 'removes unncessary empty registration and dissemination nodes' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <administrativeMetadata>
              <registration>
                <workflow id="goobiWF"/>
                <collection id="druid:fm742nb7315"/>
              </registration>
              <dissemination>
                <workflow id="someNotEmptyValue"/>
              </dissemination>
            </administrativeMetadata>
          XML
        )
      end
    end
  end
end
