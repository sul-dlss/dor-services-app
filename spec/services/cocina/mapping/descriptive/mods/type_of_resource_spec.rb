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
          form: [
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
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
          form: [
            {
              value: 'notated music',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'sound recording-musical',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multiple types and one predominant' do
    xit 'not implemented: status primary for typeOfResource' do
      let(:mods) do
        <<~XML
          <typeOfResource usage="primary">text</typeOfResource>
          <typeOfResource>still image</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'text',
              status: 'primary',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'still image',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end
    end
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
          form: [
            {
              value: 'mixed material',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'manuscript',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Manuscript without value' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource manuscript="yes" />
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'manuscript',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end
    end
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
          form: [
            {
              value: 'mixed material',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'collection',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Collection without value' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <typeOfResource collection="yes" />
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'collection',
              source: {
                value: 'MODS resource types'
              }
            }

          ]
        }
      end
    end
  end

  describe 'With authority' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <typeOfResource authorityURI="http://id.loc.gov/vocabulary/resourceTypes/" valueURI="http://id.loc.gov/vocabulary/resourceTypes/dat">Dataset</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Dataset',
              type: 'resource type',
              uri: 'http://id.loc.gov/vocabulary/resourceTypes/dat',
              source: {
                uri: 'http://id.loc.gov/vocabulary/resourceTypes/'
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
          form: [
            {
              value: 'text',
              type: 'resource type',
              displayLabel: 'Contains only',
              source: {
                value: 'MODS resource types'
              }
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
          <typeOfResource usage="primary">text</typeOfResource>
          <typeOfResource usage="primary">moving image</typeOfResource>
        XML
      end

      let(:roundtrip_mods) do
        # Drop all instances of usage="primary" after first one
        <<~XML
          <typeOfResource usage="primary">text</typeOfResource>
          <typeOfResource>moving image</typeOfResource>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'text',
              type: 'resource type',
              status: 'primary',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'moving image',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'Multiple marked as primary', context: { type: 'resource type' })
        ]
      end
    end
  end
end
