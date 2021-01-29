# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject temporal <--> cocina mappings' do
  describe 'Temporal subject with encoding' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <temporal encoding="w3cdtf">1922-05-15</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: '1922-05-15',
              encoding: {
                code: 'w3cdtf'
              },
              type: 'time'
            }
          ]
        }
      end
    end
  end

  describe 'Temporal subject with range' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <temporal encoding="w3cdtf" point="start">1890-06-11</temporal>
            <temporal encoding="w3cdtf" point="end">1894-03-19</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: '1890-06-11',
                  type: 'start'
                },
                {
                  value: '1894-03-19',
                  type: 'end'
                }
              ],
              encoding: {
                code: 'w3cdtf'
              },
              type: 'time'
            }
          ]
        }
      end
    end
  end
end
