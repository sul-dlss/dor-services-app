# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for form (H2 specific)' do
  # Mapping of H2 types and subtypes to DataCite resource types:
  # https://docs.google.com/spreadsheets/d/1EiGgVqtb6PUJE2cI_jhqnAoiQkiwZtar4tF7NHwSMz8/edit?usp=sharing
  # DataCite term always maps to resourceTypeGeneral
  # H2 subtype maps to resourceType
  # If multiple H2 subtypes, concatenate with semicolon space
  # If no H2 subtype, map H2 type to resourceType
  describe 'type only' do
    # User enters type: Data, subtype: nil
    xit 'not implemented' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Data',
                  type: 'type'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'Dataset',
              type: 'resource type',
              uri: 'http://id.loc.gov/vocabulary/resourceTypes/dat',
              source: {
                uri: 'http://id.loc.gov/vocabulary/resourceTypes/'
              }
            },
            {
              value: 'Data sets',
              type: 'genre',
              uri: 'https://id.loc.gov/authorities/genreForms/gf2018026119',
              source: {
                code: 'lcgft'
              }
            },
            {
              value: 'dataset',
              type: 'genre',
              source: {
                code: 'local'
              }
            },
            {
              value: 'Dataset',
              type: 'resource type',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <resourceType resourceTypeGeneral="Dataset">Data</resourceType>
        XML
      end
    end
  end

  describe 'type with subtype' do
    # User enters type Text, subtype Documentation
    xit 'not implemented' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Text',
                  type: 'type'
                },
                {
                  value: 'Documentation',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'Text',
              type: 'resource type',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <resourceType resourceTypeGeneral="Text">Documentation</resourceType>
        XML
      end
    end
  end

  describe 'type with multiple subtypes' do
    # User enters type: Software/Code, subtype: Code, Documentation
    xit 'not implemented' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Software/Code',
                  type: 'type'
                },
                {
                  value: 'Code',
                  type: 'subtype'
                },
                {
                  value: 'Documentation',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'software, multimedia',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'computer program',
              uri: 'http://id.loc.gov/vocabulary/marcgt/com',
              source: {
                code: 'marcgt'
              }
            },
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'Software',
              type: 'resource type',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <resourceType resourceTypeGeneral="Software">Code; Documentation</resourceType>
        XML
      end
    end
  end

  describe 'type Other with user-entered subtype' do
    # User enters type: Other, subtype: Dance notation
    xit 'not implemented' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Other',
                  type: 'type'
                },
                {
                  value: 'Dance notation',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'Other',
              type: 'resource type',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <resourceType resourceTypeGeneral="Other">Dance notation</resourceType>
        XML
      end
    end
  end
end
