# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::AdministrativeMetadata do
  subject(:write) do
    described_class.write(datastream, administrative)
  end

  let(:datastream) do
    Dor::AdministrativeMetadataDS.from_xml(existing)
  end

  let(:administrative) do
    Cocina::Models::AdminPolicyAdministrative.new(
      hasAdminPolicy: 'druid:bc123df4567',
      registrationWorkflow: ['registrationWF', 'assemblyWF'],
      disseminationWorkflow: 'wasWF',
      collectionsForRegistration: ['druid:pp562fx0548', 'druid:qy781dy0220']
    )
  end

  context 'when the existing xml is mostly empty' do
    let(:existing) do
      <<~XML
        <administrativeMetadata>
          <registration/>
        </administrativeMetadata>
      XML
    end

    let(:expected) do
      <<~XML
        <administrativeMetadata>\n
          <registration>
            <workflow id=\"registrationWF\"/>
            <workflow id=\"assemblyWF\"/>
            <collection id=\"druid:pp562fx0548\"/>
            <collection id=\"druid:qy781dy0220\"/>
          </registration>\n
          <dissemination>
            <workflow id=\"wasWF\"/>
          </dissemination>
        </administrativeMetadata>
      XML
    end

    it 'writes the converted structure' do
      write
      expect(datastream.content).to be_equivalent_to expected
    end
  end

  context 'when the xml has some existing values' do
    let(:existing) do
      <<~XML
        <administrativeMetadata>\n
          <registration>
            <workflow id=\"foo\"/>
            <workflow id=\"bar\"/>
            <collection id=\"druid:123\"/>
            <collection id=\"druid:456\"/>
          </registration>\n
          <dissemination>
            <workflow id=\"other stuff\"/>
          </dissemination>
        </administrativeMetadata>
      XML
    end

    let(:expected) do
      <<~XML
        <administrativeMetadata>
          <registration>
            <workflow id="registrationWF"/>
            <workflow id="assemblyWF"/>
            <collection id="druid:pp562fx0548"/>
            <collection id="druid:qy781dy0220"/>
          </registration>
          <dissemination>
            <workflow id="wasWF"/>
          </dissemination>
        </administrativeMetadata>
      XML
    end

    it 'writes without leaving unused nodes' do
      write
      expect(datastream.content).to be_equivalent_to expected
    end
  end

  context 'when the administrative xml is empty node' do
    let(:administrative) do
      Cocina::Models::AdminPolicyAdministrative.new(
        hasAdminPolicy: 'druid:bc123df4567',
        registrationWorkflow: [],
        collectionsForRegistration: []
      )
    end
    let(:existing) do
      <<~XML
        <administrativeMetadata/>
      XML
    end

    let(:expected) do
      <<~XML
        <administrativeMetadata/>
      XML
    end

    it 'writes the converted structure' do
      write
      expect(datastream.content).to be_equivalent_to expected
    end
  end
end
