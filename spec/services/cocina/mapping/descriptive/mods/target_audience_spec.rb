# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS targetAudience <--> cocina mappings' do
  describe 'Target audience with authority' do
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

  describe 'Target audience without authority' do
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

  describe 'Target audience with displayLabel' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <targetAudience displayLabel="Interest age level">ages 3-6</targetAudience>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'ages 3-6',
              type: 'target audience',
              displayLabel: 'Interest age level'
            }
          ]
        }
      end
    end
  end
end
