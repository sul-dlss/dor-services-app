# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'With multiple primary' do
    xit 'not implemented'

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
          <genre usage="primary">Prose</genre>
        </subject>
      XML
    end

    let(:cocina) do
      {
        subject: [
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
      }
    end

    let(:warnings) do
      [
        Notification.new(msg: 'Multiple genre subjects marked as primary')
      ]
    end
  end
end
