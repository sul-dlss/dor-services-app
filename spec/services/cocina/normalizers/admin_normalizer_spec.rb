# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::AdminNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(admin_ng_xml: Nokogiri::XML(original_xml)) }

  describe '#remove_desc_metadata_format_mods' do
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

    it 'removes descMetadata node with format of MODS' do
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

  describe '#remove_desc_metadata_source' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <descMetadata>
            <source>Symphony</source>
          </descMetadata>
          <registration>
            <workflow id="registrationWF"/>
            <collection id="druid:rt210jg0056"/>
          </registration>
        </administrativeMetadata>
      XML
    end

    it 'removes descMetadata node with source child' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <collection id="druid:rt210jg0056"/>
            </registration>
          </administrativeMetadata>
        XML
      )
    end
  end

  describe '#remove_relationships' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <relationships xmlns:fedora-rel="info:fedora/fedora-system:def/relations-external#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <fedora-rel:isMemberOf rdf:resource="info:fedora/druid:rt210jg0056"/>
            <fedora-rel:isMemberOfCollection rdf:resource="info:fedora/druid:rt210jg0056"/>
          </relationships>
          <registration>
            <workflow id="registrationWF"/>
            <collection id="druid:rt210jg0056"/>
          </registration>
        </administrativeMetadata>
      XML
    end

    it 'removes relationships node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <collection id="druid:rt210jg0056"/>
            </registration>
          </administrativeMetadata>
        XML
      )
    end
  end

  describe '#remove_assembly_node' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <registration>
            <workflow id="registrationWF"/>
            <collection id="druid:rt210jg0056"/>
          </registration>
          <assembly>
            <workflow id="assemblyWF"/>
          </assembly>
        </administrativeMetadata>
      XML
    end

    it 'removes assembly node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <collection id="druid:rt210jg0056"/>
            </registration>
          </administrativeMetadata>
        XML
      )
    end
  end

  describe '#remove_accessioning_node' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <registration>
            <workflow id="registrationWF"/>
            <collection id="druid:rt210jg0056"/>
          </registration>
          <accessioning>
            <workflow id="accessionWF"/>
          </accessioning>
        </administrativeMetadata>
      XML
    end

    it 'removes accessioning node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <collection id="druid:rt210jg0056"/>
            </registration>
          </administrativeMetadata>
        XML
      )
    end
  end

  describe '#remove_empty_registration_and_dissemination' do
    #  adapted from bb329pr4129
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
          <dissemination>
            <workflow id=""/>
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

  describe '#remove_empty_dissemination_workflow' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata>
          <dissemination>
            <workflow id=""/>
          </dissemination>
        </administrativeMetadata>
      XML
    end

    it 'removes dissemination nodes' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata/>
        XML
      )
    end
  end

  describe '#remove_object_id_attr' do
    let(:original_xml) do
      <<~XML
        <administrativeMetadata objectId="druid:cg616xd9084">
          <dissemination>
            <workflow id="someNotEmptyValue"/>
          </dissemination>
        </administrativeMetadata>
      XML
    end

    it 'removes objectId attribute' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <administrativeMetadata>
            <dissemination>
              <workflow id="someNotEmptyValue"/>
            </dissemination>
          </administrativeMetadata>
        XML
      )
    end
  end
end
