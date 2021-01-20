# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS abstract <--> cocina mappings' do
  describe 'single abstract' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <abstract>This is an abstract.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is an abstract.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end

  describe 'multilingual abstract' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <abstract lang='eng' script='Latn' altRepGroup='1'>This is an abstract.</abstract>
          <abstract lang='rus' script='Cyrl' altRepGroup='1'>Это аннотация.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              type: 'summary',
              parallelValue: [
                {
                  value: 'This is an abstract.',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: 'Это аннотация.',
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <abstract displayLabel='Synopsis'>This is a synopsis.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a synopsis.',
              type: 'summary',
              displayLabel: 'Synopsis'
            }
          ]
        }
      end
    end
  end

  describe 'abstract with type "summary"' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <abstract type="summary">This is a summary.</abstract>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract>This is a summary.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a summary.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end
end
