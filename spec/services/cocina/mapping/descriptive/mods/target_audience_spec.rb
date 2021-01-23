# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS targetAudience <--> cocina mappings' do
  describe 'with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <targetAudience authority="marctarget">juvenile</targetAudience>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'juvenile',
              type: 'target audience',
              source: {
                code: 'marctarget'
              }
            }
          ]
        }
      end
    end
  end

  describe 'without authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <targetAudience>ages 3-6</targetAudience>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'ages 3-6',
              type: 'target audience'
            }
          ]
        }
      end
    end
  end
end
