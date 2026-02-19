# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Language do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with multiple duplicate languages' do
      # 008/35-37, 041 $a, $b, $d, $e, $f, $g, $h, $j
      let(:marc_hash) do
        {
          'fields' => [
            {
              '008' => '170419p20172015fr opnn  di       n fre d'
            },
            {
              '041' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'd' => 'fre'
                  },
                  {
                    'd' => 'ger'
                  },
                  {
                    'd' => 'ita'
                  },
                  {
                    'e' => 'fre'
                  },
                  {
                    'e' => 'eng'
                  },
                  {
                    'e' => 'ger'
                  },
                  {
                    'e' => 'ita'
                  },
                  {
                    'n' => 'fre'
                  },
                  {
                    'n' => 'ger'
                  },
                  {
                    'n' => 'ita'
                  },
                  {
                    'g' => 'eng'
                  },
                  {
                    'g' => 'fre'
                  },
                  {
                    'g' => 'ger'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns language list' do
        expect(build).to eq [{ code: 'fre' }, { code: 'ger' }, { code: 'ita' }, { code: 'eng' }]
      end
    end

    context 'with invalid languages' do
      # 008/35-37, 041 $a, $b, $d, $e, $f, $g, $h, $j
      let(:marc_hash) do
        {
          'fields' => [
            {
              '008' => '170419p20172015fr opnn  di       n frz d'
            },
            {
              '041' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'd' => 'fre'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'drops invalid languages' do
        expect(build).to eq [{ code: 'fre' }]
      end
    end
  end
end
