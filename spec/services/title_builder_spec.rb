# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TitleBuilder do
  subject { described_class.build(cocina_titles) }

  # lots more specs in spec/indexers/descriptive_metadata/title_spec

  context 'when structuredValue in structuredValue' do
    # from a spreadsheet upload integration test
    #   https://argo-stage.stanford.edu/view/sk561pf3505
    let(:cocina_titles) do
      [
        # Yes, there can be a structuredValue inside a StructuredValue.  For example,
        # a uniform title where both the name and the title have internal StructuredValue
        Cocina::Models::Title.new(
          structuredValue: [
            {
              structuredValue: [
                {
                  value: 'ti1:nonSort',
                  type: 'nonsorting characters'
                },
                {
                  value: 'brisk junket',
                  type: 'main title'
                },
                {
                  value: 'ti1:subTitle',
                  type: 'subtitle'
                },
                {
                  value: 'ti1:partNumber',
                  type: 'part number'
                },
                {
                  value: 'ti1:partName',
                  type: 'part name'
                }
              ]
            }
          ]
        )
      ]
    end

    it { is_expected.to eq 'ti1:nonSortbrisk junket : ti1:subTitle. ti1:partNumber, ti1:partName' }
  end

  context 'when multiple nonsorting characters' do
    let(:cocina_titles) do
      [
        Cocina::Models::Title.new(
          {
            structuredValue: [
              {
                value: 'The',
                type: 'nonsorting characters'
              }, {
                value: 'means to prosperity',
                type: 'main title'
              }
            ],
            note: [
              {
                value: '5',
                type: 'nonsorting character count'
              }
            ]
          }
        )
      ]
    end

    it { is_expected.to eq 'The  means to prosperity' }
  end
end
