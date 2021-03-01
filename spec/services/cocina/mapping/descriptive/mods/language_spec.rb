# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS language <--> cocina mappings' do
  describe 'Single language with term, code, and authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English',
              code: 'eng',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
              source: {
                code: 'iso639-2b',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Language term only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language>
            <languageTerm type="text">English</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English'
            }
          ]
        }
      end
    end
  end

  describe 'Language code only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language>
            <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              code: 'eng',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multiple languages' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language usage="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </language>
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">French</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">fre</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English',
              code: 'eng',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
              source: {
                code: 'iso639-2b',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/'
              },
              status: 'primary'
            },
            {
              value: 'French',
              code: 'fre',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/fre',
              source: {
                code: 'iso639-2b',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Language with script and authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">Russian</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/"
              valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">rus</languageTerm>
            <scriptTerm type="text" authority="iso15924">Cyrillic</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Cyrl</scriptTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'Russian',
              code: 'rus',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/rus',
              source: {
                code: 'iso639-2b',
                uri: 'http://id.loc.gov/vocabulary/iso639-2/'
              },
              script: {
                value: 'Cyrillic',
                code: 'Cyrl',
                source: {
                  code: 'iso15924'
                }
              }
            }
          ]
        }
      end
    end
  end

  describe 'Script only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language>
            <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              script: {
                value: 'Latin',
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'languageTerm missing type', context: nil)] }
    end
  end

  describe 'Applies to part of object' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <language objectPart="liner notes">
            <languageTerm type="text">English</languageTerm>
          </language>
          <language objectPart="libretto">
            <languageTerm type="text">German</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English',
              appliesTo: [
                {
                  value: 'liner notes'
                }
              ]
            },
            {
              value: 'German',
              appliesTo: [
                {
                  value: 'libretto'
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
          <language displayLabel="Translated to">
            <languageTerm type="text">English</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English',
              displayLabel: 'Translated to'
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
          <language usage="primary">
            <languageTerm type="text" authority="iso639-2b">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
          </language>
          <language usage="primary">
            <languageTerm type="text" authority="iso639-2b">French</languageTerm>
            <languageTerm type="code" authority="iso639-2b">fre</languageTerm>
          </language>
        XML
      end

      let(:roundtrip_mods) do
        # Drop all instances of usage="primary" after first one
        <<~XML
          <language usage="primary">
            <languageTerm type="text" authority="iso639-2b">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
          </language>
          <language>
            <languageTerm type="text" authority="iso639-2b">French</languageTerm>
            <languageTerm type="code" authority="iso639-2b">fre</languageTerm>
          </language>
        XML
      end

      let(:cocina) do
        {
          language: [
            {
              value: 'English',
              code: 'eng',
              status: 'primary',
              source: {
                code: 'iso639-2b'
              }
            },
            {
              value: 'French',
              code: 'fre',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Multiple marked as primary', context: { type: 'language' })
        ]
      end
    end
  end
end
