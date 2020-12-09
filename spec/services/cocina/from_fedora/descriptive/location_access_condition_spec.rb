# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Location do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  # examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_accessCondition.txt

  # example 1A from mods_to_cocina_accessCondition.txt
  context 'with a restriction on access' do
    let(:xml) do
      <<~XML
        <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'Available to Stanford researchers only.',
              "type": 'access restriction'
            }
          ]
        }
      )
    end
  end

  # example 1B from mods_to_cocina_accessCondition.txt
  context 'with a restriction on access without spaces' do
    let(:xml) do
      <<~XML
        <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'Available to Stanford researchers only.',
              "type": 'access restriction'
            }
          ]
        }
      )
    end
  end

  # example 2A from mods_to_cocina_accessCondition.txt
  context 'with a restriction on use and reproduction' do
    let(:xml) do
      <<~XML
        <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.',
              "type": 'use and reproduction'
            }
          ]
        }
      )
    end
  end

  # example 2B from mods_to_cocina_accessCondition.txt
  context 'with a restriction on use and reproduction without spaces' do
    let(:xml) do
      <<~XML
        <accessCondition type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.',
              "type": 'use and reproduction'
            }
          ]
        }
      )
    end
  end

  # example 3 from mods_to_cocina_accessCondition.txt
  context 'with a license' do
    let(:xml) do
      <<~XML
        <accessCondition type="license">CC by: CC BY Attribution</accessCondition>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          "note": [
            {
              "value": 'CC by: CC BY Attribution',
              "type": 'license'
            }
          ]
        }
      )
    end
  end
end
