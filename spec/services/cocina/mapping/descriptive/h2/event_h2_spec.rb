# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for event (h2 specific)' do
  describe 'Publication date: 2021-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">2021-01-01</dateIssued>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated encoding="w3cdtf">2021-01-01</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date range: 2020-01-01 to 2021-01-01' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '2020-01-01',
                      type: 'start'
                    },
                    {
                      value: '2021-01-01',
                      type: 'end'
                    }
                  ],
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated point="start" encoding="w3cdtf">2020-01-01</dateCreated>
            <dateCreated point="end" encoding="w3cdtf">2021-01-01</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate creation date: approx. 1900' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start'
                    },
                    {
                      value: '1910',
                      type: 'end'
                    }
                  ],
                  qualifier: 'approximate',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated qualifier="approximate" point="start" encoding="w3cdtf">1900</dateCreated>
            <dateCreated qualifier="approximate" point="end" encoding="w3cdtf">1910</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Release date: 2022-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'release',
              date: [
                {
                  value: '2022-01-01',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="release">
            <dateIssued encoding="w3cdtf">2022-01-01</dateIssued>
          </originInfo>
        XML
      end
    end
  end
end
