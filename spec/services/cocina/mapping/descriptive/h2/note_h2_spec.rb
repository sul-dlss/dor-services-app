# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for note' do
  describe 'Abstract' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          note: [
            {
              type: 'abstract',
              value: 'My paper is about dolphins.'
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
  end

  describe 'Preferred citation' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          note: [
            type: 'preferred citation',
            value: 'Me (2002). Our friend the dolphin.'
          ]
        }
      end

      let(:mods) do
        <<~XML
          <note type="preferred citation">Me (2002). Our friend the dolphin.</note>
        XML
      end
    end
  end
end
