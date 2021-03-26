# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for form (H2 specific)' do
  # Mapping of H2 types and subtypes to genre and MODS type of resource:
  # https://docs.google.com/spreadsheets/d/1EiGgVqtb6PUJE2cI_jhqnAoiQkiwZtar4tF7NHwSMz8/edit?usp=sharing

  describe 'Text - Article (AAT genre)' do
    it_behaves_like 'cocina MODS mapping' do
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
              value: 'articles',
              type: 'genre',
              uri: 'http://vocab.getty.edu/page/aat/300048715',
              source: {
                code: 'aat'
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
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Article</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/page/aat/300048715">articles</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end
    end
  end

  describe 'Text - Essay (LC genre)' do
    it_behaves_like 'cocina MODS mapping' do
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
                  value: 'Essay',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'Essays',
              type: 'genre',
              uri: 'http://id.loc.gov/authorities/genreForms/gf2014026094',
              source: {
                code: 'lcgft'
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
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Essay</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2014026094">Essays</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end
    end
  end

  describe 'Data - 3D model (unauthorized genre)' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Data',
                  type: 'type'
                },
                {
                  value: '3D model',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'Data sets',
              type: 'genre',
              uri: 'http://id.loc.gov/authorities/genreForms/gf2018026119',
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
              value: 'software, multimedia',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'three-dimensional object',
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
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">3D model</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2018026119">Data sets</genre>
          <genre authority="local">dataset</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <typeOfResource>three-dimensional object</typeOfResource>
        XML
      end
    end
  end

  describe 'Data - GIS (multiple genres, multiple types of resource)' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Data',
                  type: 'type'
                },
                {
                  value: 'Geospatial data',
                  type: 'subtype'
                }
              ],
              source: {
                value: 'Stanford self-deposit resource types'
              },
              type: 'resource type'
            },
            {
              value: 'Data sets',
              type: 'genre',
              uri: 'http://id.loc.gov/authorities/genreForms/gf2018026119',
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
              value: 'Geographic information systems',
              type: 'genre',
              uri: 'http://id.loc.gov/authorities/genreForms/gf2011026294',
              source: {
                code: 'lcgft'
              }
            },
            {
              value: 'software, multimedia',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'cartographic',
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
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">Geospatial data</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2018026119">Data sets</genre>
          <genre authority="local">dataset</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2011026294">Geographic information systems</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <typeOfResource>cartographic</typeOfResource>
        XML
      end
    end
  end

  describe 'Software - Code, Documentation (multiple subtypes)' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'Software',
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
              value: 'programs (computer)',
              type: 'genre',
              uri: 'http://vocab.getty.edu/page/aat/300312188',
              source: {
                code: 'aat'
              }
            },
            {
              value: 'technical manuals',
              type: 'genre',
              uri: 'http://vocab.getty.edu/aat/300026413',
              source: {
                code: 'aat'
              }
            },
            {
              value: 'software, multimedia',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
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
          <genre type="H2 type">Software</genre>
          <genre type="H2 subtype">Code</genre>
          <genre type="H2 subtype">Documentation</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/page/aat/300312188">programs (computer)</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300026413">technical manuals</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <typeOfResource>text</typeOfResource>
        XML
      end
    end
  end

  describe 'Other - Dance notation (Other type with user-entered subtype)' do
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
