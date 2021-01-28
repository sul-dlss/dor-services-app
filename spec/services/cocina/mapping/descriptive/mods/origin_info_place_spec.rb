# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo place <--> cocina mappings' do
  describe 'Place - text (authorized)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'publication',
              "location": [
                {
                  "value": 'Stanford (Calif.)',
                  "uri": 'http://id.loc.gov/authorities/names/n50046557',
                  "source": {
                    "code": 'naf',
                    "uri": 'http://id.loc.gov/authorities/names/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Place - code' do
    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <place>
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        "event": [
          {
            "type": 'publication',
            "location": [
              {
                "code": 'cau',
                "uri": 'http://id.loc.gov/vocabulary/countries/cau',
                "source": {
                  "code": 'marccountry',
                  "uri": 'http://id.loc.gov/vocabulary/countries/'
                }
              }
            ]
          }
        ]
      }
    end

    xit 'broken'
  end

  describe 'Place - text and code for same place' do
    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <place>
            <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        "event": [
          {
            "type": 'publication',
            "location": [
              {
                "value": 'California',
                "code": 'cau',
                "uri": 'http://id.loc.gov/vocabulary/countries/cau',
                "source": {
                  "code": 'marccountry',
                  "uri": 'http://id.loc.gov/vocabulary/countries/'
                }
              }
            ]
          }
        ]
      }
    end

    xit 'broken'
  end

  describe 'Place - text and code for different places - Version A (converted from MARC, standard MODS)' do
    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <place>
            <placeTerm type="code" authority="marccountry">enk</placeTerm>
          </place>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        "event": [
          {
            "type": 'publication',
            "location": [
              {
                "code": 'enk',
                "source": {
                  "code": 'marccountry'
                }
              },
              {
                "value": 'London'
              }
            ]
          }
        ]
      }
    end

    xit 'broken'
  end

  describe 'Place - text and code for different places - Version B (from replayable spreadsheet, incorrect MODS)' do
    # The authority value goes with the code term and the authorityURI and valueURI values go with the text term.
    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <place>
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">cau</placeTerm>
            <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        "event": [
          {
            "type": 'publication',
            "location": [
              {
                "code": 'cau',
                "source": {
                  "code": 'marccountry'
                }
              },
              {
                "value": 'Stanford (Calif.)',
                "uri": 'http://id.loc.gov/authorities/names/n50046557',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/'
                }
              }
            ]
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Supplied place name' do
    # Adapted from druid:bv279kp1172

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production" displayLabel="Place of creation">
            <place supplied="yes">
              <placeTerm authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n81127564" type="text">Selma (Ala.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">1965</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'creation',
              "displayLabel": 'Place of creation',
              "location": [
                {
                  "type": 'supplied',
                  "value": 'Selma (Ala.)',
                  "uri": 'http://id.loc.gov/authorities/names/n81127564',
                  "source": {
                    "uri": 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              "date": [
                {
                  "value": '1965',
                  "encoding": {
                    "code": 'w3cdtf'
                  },
                  "status": 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end
end
