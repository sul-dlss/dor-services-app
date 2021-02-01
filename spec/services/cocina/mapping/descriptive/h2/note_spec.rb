# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for note' do
  xit 'not implemented: MODS mapping'

  describe 'Abstract' do
    let(:cocina) do
      {
        "note": [
          {
            "type": 'summary',
            "displayLabel": 'Abstract',
            "value": 'My paper is about dolphins.'
          }
        ]
      }
    end

    let(:mods) do
      <<~XML
        <abstract>My paper is about dolphins.</abstract>
      XML
    end
  end

  describe 'Preferred citation' do
    xit 'not implemented: MODS mapping'
    
    let(:cocina) do
      {
        "note": [
          "type": 'preferred citation',
          "value": 'Me (2002). Our friend the dolphin.'
        ]
      }
    end

    let(:mods) do
      <<~XML
        <note type="preferred citation" displayLabel="Preferred citation">Me (2002). Our friend the dolphin.</note>
      XML
    end
  end
end
