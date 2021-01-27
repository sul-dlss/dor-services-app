# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for note' do
  describe 'Abstract' do
    let(:cocina) do
      {
        "note": [
          {
            "type": 'summary',
            "displayLabel": 'abstract',
            "value": 'My paper is about dolphins.'
          }
        ]
      }
    end

    xit 'not mapped'
  end

  describe 'Preferred citation' do
    let(:cocina) do
      {
        "note": [
          "type": 'preferred citation',
          "value": 'Me (2002). Our friend the dolphin.'
        ]
      }
    end

    xit 'not mapped'
  end
end
