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
        expect(build).to eq [
          { code: 'fre', source: { code: 'iso639-2b' } },
          { code: 'ger', source: { code: 'iso639-2b' } },
          { code: 'ita', source: { code: 'iso639-2b' } },
          { code: 'eng', source: { code: 'iso639-2b' } }
        ]
      end
    end

    context 'with additional subfields' do
      # 008/35-37, 041 $a, $b, $d, $e, $f, $g, $h, $j + $i, $k, $m, $n, $p, $q, $r, $t, $2
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
                    'i' => 'fre'
                  },
                  {
                    'k' => 'ger'
                  },
                  {
                    'm' => 'ita'
                  },
                  {
                    'n' => 'fre'
                  },
                  {
                    'p' => 'eng'
                  },
                  {
                    'q' => 'ger'
                  },
                  {
                    'r' => 'ita'
                  },
                  {
                    't' => 'fre'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns language list' do
        expect(build).to eq [{ code: 'fre', source: { code: 'iso639-2b' } }, { code: 'ger', source: { code: 'iso639-2b' } }, { code: 'ita', source: { code: 'iso639-2b' } }, { code: 'eng', source: { code: 'iso639-2b' } }]
      end
    end

    context 'with source code in $2' do
      # 008/35-37, 041 $a, $b, $d, $e, $f, $g, $h, $j + $i, $k, $m, $n, $p, $q, $r, $t, $2
      let(:marc_hash) do
        {
          'fields' => [
            {
              '008' => '170419p20172015fr opnn  di       n eng d'
            },
            {
              '041' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'd' => 'eng'
                  }
                ]
              }
            },
            {
              '041' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'r' => 'asn',
                    '2' => 'iso639-3'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns language list' do
        expect(build).to eq [
          { code: 'eng', source: { code: 'iso639-2b' } },
          { code: 'asn', source: { code: 'iso639-3' } }
        ]
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
        expect(build).to eq [{ code: 'fre', source: { code: 'iso639-2b' } }]
      end
    end
  end
end
