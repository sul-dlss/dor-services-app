# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for form (H2 specific)' do
  # Mapping of H2 types and subtypes to genre and MODS type of resource:
  # https://docs.google.com/spreadsheets/d/1EiGgVqtb6PUJE2cI_jhqnAoiQkiwZtar4tF7NHwSMz8/edit?usp=sharing
  describe 'type only, resource type with URI' do
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
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <genre type="H2 type">Data</genre>
          <typeOfResource authorityURI="http://id.loc.gov/vocabulary/resourceTypes/" valueURI="http://id.loc.gov/vocabulary/resourceTypes/dat">Dataset</typeOfResource>
          <genre authority="lcgft" valueURI="https://id.loc.gov/authorities/genreForms/gf2018026119">Data sets</genre>
          <genre authority="local">dataset</genre>
        XML
      end
    end
  end

  describe 'type with subtype' do
    # User enters type: Text, subtype: Article
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
                  value: 'Article',
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
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Article</genre>
          <typeOfResource>text</typeOfResource>
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
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <genre type="H2 type">Software/Code</genre>
          <genre type="H2 subtype">Code</genre>
          <genre type="H2 subtype">Documentation</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <genre authority="marcgt" valueURI="http://id.loc.gov/vocabulary/marcgt/com">computer program</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end
    end
  end

  describe 'type with user-entered subtype' do
    # User enters type: Other, subtype: Dance notation
    it_behaves_like 'cocina MODS mapping' do
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
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <genre type="H2 type">Other</genre>
          <genre type="H2 subtype">Dance notation</genre>
        XML
      end
    end
  end
end
