# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'Subject with only titleInfo subelement' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <subject authority="lcsh">
          <titleInfo authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79018834">
            <title>Beowulf</title>
          </titleInfo>
        </subject>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            value: 'Beowulf',
            type: 'title',
            uri: 'http://id.loc.gov/authorities/names/n79018834',
            source: {
              code: 'lcsh',
              uri: 'http://id.loc.gov/authorities/names/'
            }
          }
        ]
      }
    end
  end

  describe 'Subject with only titleInfo subelement, multipart title' do
    # Example from gp286dy1254
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <subject authority="lcsh">
          <titleInfo>
            <title>Bible. English 1975</title>
            <partName>Jonah. English 1975</partName>
          </titleInfo>
        </subject>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            structuredValue: [
              {
                value: 'Bible. English 1975',
                type: 'main title'
              },
              {
                value: 'Jonah. English 1975',
                type: 'part name'
              }
            ],
            type: 'title',
            source: {
              code: 'lcsh'
            }
          }
        ]
      }
    end
  end
end
