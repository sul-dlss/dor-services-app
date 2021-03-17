# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'Subject with only genre subelement' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <genre>Melodrama</genre>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Melodrama',
              type: 'genre'
            }
          ]
        }
      end
    end
  end

  describe 'Genre subject with display label on subelement' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <genre displayLabel="Drama type">Melodrama</genre>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Melodrama',
              type: 'genre',
              displayLabel: 'Drama type'
            }
          ]
        }
      end
    end
  end

  describe 'Genre subject with type' do
    xit 'not implemented: genre subject with type' do
      let(:mods) do
        <<~XML
          <subject>
            <genre type="style">Art Deco</genre>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
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

  # Bad data handling

  describe 'With multiple primary' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <genre usage="primary">Poetry</genre>
            <genre usage="primary">Prose</genre>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        # Drop all instances of usage="primary" after first one
        <<~XML
          <subject>
            <genre usage="primary">Poetry</genre>
            <genre>Prose</genre>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            structuredValue: [
              {
                value: 'Poetry',
                type: 'genre',
                status: 'primary'
              },
              {
                value: 'Prose',
                type: 'genre'
              }
            ]
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
