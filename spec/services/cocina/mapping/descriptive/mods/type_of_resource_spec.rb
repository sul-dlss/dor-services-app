# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS typeOfResource <--> cocina mappings' do
  describe 'Object with one type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource>text</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'text',
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Object with multiple types' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource>notated music</typeOfResource>
          <typeOfResource>sound recording-musical</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'notated music',
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            },
            {
              "value": 'sound recording-musical',
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multiple types and one predominant' do
    let(:mods) do
      <<~XML
        <typeOfResource usage="primary">text</typeOfResource>
        <typeOfResource>still image</typeOfResource>
      XML
    end

    let(:cocina) do
      {
        "form": [
          {
            "value": 'text',
            "status": 'primary',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource types'
            }
          },
          {
            "value": 'still image',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Manuscript' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource manuscript="yes">mixed material</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'mixed material',
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            },
            {
              "value": 'manuscript',
              "source": {
                "value": 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Attribute without value' do
    let(:mods) do
      <<~XML
        <typeOfResource manuscript="yes" />
      XML
    end

    let(:cocina) do
      {
        "form": [
          {
            "value": 'manuscript',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Collection' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource collection="yes">mixed material</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'mixed material',
              "type": 'resource type',
              "source": {
                "value": 'MODS resource types'
              }
            },
            {
              "value": 'collection',
              "source": {
                "value": 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'With display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource displayLabel="Contains only">text</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          "form": [
            {
              "value": 'text',
              "type": 'resource type',
              "displayLabel": 'Contains only',
              "source": {
                "value": 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end
end
