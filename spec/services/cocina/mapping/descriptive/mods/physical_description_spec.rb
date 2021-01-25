# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS physicalDescription <--> cocina mappings' do
  describe 'Single physical description with all subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <reformattingQuality>access</reformattingQuality>
            <internetMediaType>image/jpeg</internetMediaType>
            <extent>1 sheet</extent>
            <digitalOrigin>reformatted digital</digitalOrigin>
            <note displayLabel="Condition">Small tear at top right corner.</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'ink on paper',
              "type": 'form'
            },
            {
              "value": 'access',
              "type": 'reformatting quality',
              "source": {
                "value": 'MODS reformatting quality terms'
              }
            },
            {
              "value": 'image/jpeg',
              "type": 'media type',
              "source": {
                "value": 'IANA media types'
              }
            },
            {
              "value": '1 sheet',
              "type": 'extent'
            },
            {
              "value": 'reformatted digital',
              "type": 'digital origin',
              "source": {
                "value": 'MODS digital origin terms'
              }
            },
            {
              "note": [
                {
                  "value": 'Small tear at top right corner.',
                  "displayLabel": 'Condition'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple physical descriptions' do
    let(:mods) do
      <<~XML
        <physicalDescription>
          <form>audio recording</form>
          <extent>1 audiocassette</extent>
        </physicalDescription>
        <physicalDescription>
          <form>transcript</form>
          <extent>5 pages</extent>
        </physicalDescription>
      XML
    end

    let(:cocina) do
      {
        "form": [
          {
            "structuredValue": [
              {
                "value": 'audio recording',
                "type": 'form'
              },
              {
                "value": '1 audiocassette',
                "type": 'extent'
              }
            ]
          },
          {
            "structuredValue": [
              {
                "value": 'transcript',
                "type": 'form'
              },
              {
                "value": '5 pages',
                "type": 'extent'
              }
            ]
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Form with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form authority="aat" authorityURI="http://vocab.getty.edu/aat/" valueURI="http://vocab.getty.edu/aat/300041356">mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'mezzotints (prints)',
              "type": 'form',
              "uri": 'http://vocab.getty.edu/aat/300041356',
              "source": {
                "code": 'aat',
                "uri": 'http://vocab.getty.edu/aat/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Display label' do
    let(:mods) do
      <<~XML
        <physicalDescription displayLabel="Medium">
          <form>metal embossed on wood</form>
        </physicalDescription>
      XML
    end

    let(:cocina) do
      {
        "form": [
          {
            "value": 'metal embossed on wood',
            "type": 'form',
            "displayLabel": 'Medium'
          }
        ]
      }
    end

    xit 'not implemented'
  end
end
