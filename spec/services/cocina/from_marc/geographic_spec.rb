# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Geographic do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with encoded map coordinates (034)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '034' => {
              'ind1' => '0', 'ind2' => ' ',
              'subfields' => [
                { 'a' => 'a' },
                { 'd' => 'W1115800' },
                { 'e' => 'W1104500' },
                { 'f' => 'N0353600' },
                { 'g' => 'N0342500' }
              ]
            } }
          ]
        }
      end

      it 'returns bounding box' do
        expect(build).to eq([{
                              subject: [{
                                type: 'bounding box coordinates',
                                structuredValue: [
                                  { value: 'W1115800', type: 'west' },
                                  { value: 'W1104500', type: 'east' },
                                  { value: 'N0353600', type: 'north' },
                                  { value: 'N0342500', type: 'south' }
                                ]
                              }]
                            }])
      end
    end
  end
end
