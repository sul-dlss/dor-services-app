# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS genre <--> cocina mappings' do
  describe 'Single value' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre>photographs</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'photographs',
              type: 'genre'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple values' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre>photographs</genre>
          <genre>prints</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'photographs',
              type: 'genre'
            },
            {
              value: 'prints',
              type: 'genre'
            }
          ]
        }
      end
    end
  end

  describe 'with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre type="style">Art Deco</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Art Deco',
              type: 'genre',
              note: [
                {
                  value: 'style',
                  type: 'genre type'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/"
            valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Photographs',
              type: 'genre',
              uri: 'http://id.loc.gov/authorities/genreForms/gf2017027249',
              source: {
                code: 'lcgft',
                uri: 'http://id.loc.gov/authorities/genreForms/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'With usage' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre usage="primary">photographs</genre>
          <genre>prints</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'photographs',
              status: 'primary',
              type: 'genre'
            },
            {
              value: 'prints',
              type: 'genre'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre lang="eng" script="Latn" altRepGroup="1">photographs</genre>
          <genre lang="rus" script="Cyrl" altRepGroup="1">фотографии</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              type: 'genre',
              parallelValue: [
                {
                  value: 'photographs',
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
                  value: 'фотографии',
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

  describe 'Display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre displayLabel="Style">Art deco</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Art deco',
              type: 'genre',
              displayLabel: 'Style'
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'With multiple primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <genre usage="primary">poetry</genre>
          <genre usage="primary">prose</genre>
        XML
      end

      let(:roundtrip_mods) do
        # Drop all instances of usage="primary" after first one
        <<~XML
          <genre usage="primary">poetry</genre>
          <genre>prose</genre>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'poetry',
              type: 'genre',
              status: 'primary'
            },
            {
              value: 'prose',
              type: 'genre'
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Multiple marked as primary', context: { type: 'genre' })
        ]
      end
    end
  end
end
