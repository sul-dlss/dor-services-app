# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS tableOfContents <--> cocina mappings' do
  describe 'Simple table of contents' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <tableOfContents>Chapter 1. Chapter 2. Chapter 3.</tableOfContents>
        XML
      end

      let(:cocina) do
        {
          "note": [
            {
              "value": 'Chapter 1. Chapter 2. Chapter 3.',
              "type": 'table of contents'
            }
          ]
        }
      end
    end
  end

  describe 'Structured table of contents' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <tableOfContents>Chapter 1. -- Chapter 2. -- Chapter 3.</tableOfContents>
        XML
      end

      let(:cocina) do
        {
          "note": [
            {
              "structuredValue": [
                {
                  "value": 'Chapter 1.'
                },
                {
                  "value": 'Chapter 2.'
                },
                {
                  "value": 'Chapter 3.'
                }
              ],
              "type": 'table of contents'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual table of contents' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <tableOfContents lang="eng" script="Latn" altRepGroup="1">Chapter 1. Chapter 2. Chapter 3.</tableOfContents>
          <tableOfContents lang="rus" script="Cyrl" altRepGroup="1">Глава 1. Глава 2. Глава 3.</tableOfContents>
        XML
      end

      let(:cocina) do
        {
          "note": [
            {
              "parallelValue": [
                {
                  "value": 'Chapter 1. Chapter 2. Chapter 3.',
                  "valueLanguage":
                            {
                              "code": 'eng',
                              "source": {
                                "code": 'iso639-2b'
                              },
                              "valueScript": {
                                "code": 'Latn',
                                "source": {
                                  "code": 'iso15924'
                                }
                              }
                            }
                },
                {
                  "value": 'Глава 1. Глава 2. Глава 3.',
                  "valueLanguage":
                          {
                            "code": 'rus',
                            "source": {
                              "code": 'iso639-2b'
                            },
                            "valueScript": {
                              "code": 'Cyrl',
                              "source": {
                                "code": 'iso15924'
                              }
                            }
                          }
                }
              ],
              "type": 'table of contents'
            }
          ]
        }
      end
    end
  end

  describe 'Display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <tableOfContents displayLabel="Contents">Content 1. Content 2.</tableOfContents>
        XML
      end

      let(:cocina) do
        {
          "note": [
            {
              "value": 'Content 1. Content 2.',
              "type": 'table of contents',
              "displayLabel": 'Contents'
            }
          ]
        }
      end
    end
  end
end
