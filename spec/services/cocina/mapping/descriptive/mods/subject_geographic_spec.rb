# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject geographic <--> cocina mappings' do
  describe 'Geographic subject subdivision' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic>Cats</topic>
            <geographic>Europe</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "structuredValue": [
                {
                  "value": 'Cats',
                  "type": 'topic'
                },
                {
                  "value": 'Europe',
                  "type": 'place'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Hierarchical geographic subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <hierarchicalGeographic>
              <continent>North America</continent>
              <country>Canada</country>
              <city>Vancouver</city>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "structuredValue": [
                {
                  "value": 'North America',
                  "type": 'continent'
                },
                {
                  "value": 'Canada',
                  "type": 'country'
                },
                {
                  "value": 'Vancouver',
                  "type": 'city'
                }
              ],
              "type": 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic code subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "code": 'n-us-md',
              "type": 'place',
              "source": {
                "code": 'marcgac'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Geographic code and term' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographic authority="lcsh">United States</geographic>
            <geographicCode authority="iso3166">us</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "parallelValue": [
                {
                  "value": 'United States',
                  "source": {
                    "code": 'lcsh'
                  }
                },
                {
                  "code": 'us',
                  "source": {
                    "code": 'iso3166'
                  }
                }
              ],
              "type": 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">
            <geographic>Antarctica</geographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <subject authority="lcsh">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">Antarctica</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "value": 'Antarctica',
              "uri": 'http://id.loc.gov/authorities/subjects/sh85005490',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/subjects/'
              },
              "type": 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject with language' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographic lang="eng" valueURI="http://sws.geonames.org/2960860/" authority="geonames" authorityURI="http://www.geonames.org/ontology#">Arctic Ocean</geographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <subject authority="geonames">
            <geographic authority="geonames" authorityURI="http://www.geonames.org/ontology#" valueURI="http://sws.geonames.org/2960860/" lang="eng">Arctic Ocean</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          "subject": [
            {
              "value": 'Arctic Ocean',
              "valueLanguage": {
                "code": 'eng',
                "source": {
                  "code": 'iso639-2b'
                }
              },
              "uri": 'http://sws.geonames.org/2960860/',
              "source": {
                "code": 'geonames',
                "uri": 'http://www.geonames.org/ontology#'
              },
              "type": 'place'
            }
          ]
        }
      end
    end
  end
end
