# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for form (H2 specific)' do
  # Mapping of H2 types and subtypes to DataCite resource types:
  # https://docs.google.com/spreadsheets/d/1EiGgVqtb6PUJE2cI_jhqnAoiQkiwZtar4tF7NHwSMz8/edit?usp=sharing
  # DataCite term always maps to resourceTypeGeneral
  # H2 subtype maps to resourceType
  # If multiple H2 subtypes, concatenate with semicolon space
  # If no H2 subtype, map H2 type to resourceType

  # NOTE: Because we haven't set a title in this Cocina::Models::Description, it will not validate against the openapi.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:type_attributes) { Cocina::ToDatacite::Form.type_attributes(cocina_description) }

  describe 'type only (no subtype)' do
    # User enters type: Data, subtype: nil
    let(:mods) do
      <<~XML
        <genre type="H2 type">Data</genre>
        <typeOfResource authorityURI="http://id.loc.gov/vocabulary/resourceTypes/" valueURI="http://id.loc.gov/vocabulary/resourceTypes/dat">Dataset</typeOfResource>
        <genre authority="lcgft" valueURI="https://id.loc.gov/authorities/genreForms/gf2018026119">Data sets</genre>
        <genre authority="local">dataset</genre>
        <extension displayLabel="datacite">
          <resourceType resourceTypeGeneral="Dataset">Data</resourceType>
        </extension>
      XML
    end

    it 'populates type_attributes correctly' do
      expect(type_attributes).to eq(
        {
          resourceTypeGeneral: 'Dataset',
          resourceType: 'Data'
        }
      )
    end
  end

  describe 'type with subtype' do
    # User enters type Text, subtype Article
    let(:mods) do
      <<~XML
        <genre type="H2 type">Text</genre>
        <genre type="H2 subtype">Article</genre>
        <typeOfResource>text</typeOfResource>
        <extension displayLabel="datacite">
          <resourceType resourceTypeGeneral="Text">Article</resourceType>
        </extension>
      XML
    end

    it 'populates type_attributes correctly' do
      expect(type_attributes).to eq(
        {
          resourceTypeGeneral: 'Text',
          resourceType: 'Article'
        }
      )
    end
  end

  describe 'type with multiple subtypes' do
    # User enters type: Software/Code, subtype: Code, Documentation
    let(:mods) do
      <<~XML
        <genre type="H2 type">Software/Code</genre>
        <genre type="H2 subtype">Code</genre>
        <genre type="H2 subtype">Documentation</genre>
        <typeOfResource>software, multimedia</typeOfResource>
        <genre authority="marcgt" valueURI="http://id.loc.gov/vocabulary/marcgt/com">computer program</genre>
        <typeOfResource>text</typeOfResource>
        <extension displayLabel="datacite">
          <resourceType resourceTypeGeneral="Software">Code; Documentation</resourceType>
        </extension>
      XML
    end

    it 'populates type_attributes correctly' do
      expect(type_attributes).to eq(
        {
          resourceTypeGeneral: 'Software',
          resourceType: 'Code; Documentation'
        }
      )
    end
  end

  describe 'type Other with user-entered subtype' do
    # User enters type: Other, subtype: Dance notation
    let(:mods) do
      <<~XML
        <genre type="H2 type">Other</genre>
        <genre type="H2 subtype">Dance notation</genre>
        <extension displayLabel="datacite">
          <resourceType resourceTypeGeneral="Other">Dance notation</resourceType>
        </extension>
      XML
    end

    it 'populates type_attributes correctly' do
      expect(type_attributes).to eq(
        {
          resourceTypeGeneral: 'Other',
          resourceType: 'Dance notation'
        }
      )
    end
  end
end
