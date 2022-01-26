# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::RoleNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(role_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when #normalize_empty_name_nodes' do
    let(:original_xml) do
      <<~XML
        <roleMetadata objectId="druid:qv648vd4392">
          <role type="dor-apo-manager">
            </group>
            <person>
              <identifier type="person">sunetid:petucket</identifier>
              <name/>
            </person>
            <group>
              <identifier type="workgroup">sdr:metadata-staff</identifier>
            </group>
          </role>
        </roleMetadata>
      XML
    end

    it 'removes empty <name> nodes' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <roleMetadata objectId="druid:qv648vd4392">
            <role type="dor-apo-manager">
              </group>
              <person>
                <identifier type="sunetid">petucket</identifier>
              </person>
              <group>
                <identifier type="workgroup">sdr:metadata-staff</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      )
    end
  end

  context 'when #normalize_identitifer_nodes' do
    let(:original_xml) do
      <<~XML
        <roleMetadata objectId="druid:qv648vd4392">
          <role type="dor-apo-manager">
            </group>
            <person>
              <identifier type="person">sunetid:petucket</identifier>
            </person>
            <group>
              <identifier type="workgroup">sdr:metadata-staff</identifier>
            </group>
          </role>
        </roleMetadata>
      XML
    end

    it 'converts <identifier> type="person" and prefix "sunetid:" to <identifier> type="sunetid" and removes prefix' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <roleMetadata objectId="druid:qv648vd4392">
            <role type="dor-apo-manager">
              </group>
              <person>
                <identifier type="sunetid">petucket</identifier>
              </person>
              <group>
                <identifier type="workgroup">sdr:metadata-staff</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      )
    end
  end
end
