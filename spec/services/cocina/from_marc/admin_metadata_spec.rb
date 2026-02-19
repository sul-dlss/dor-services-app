# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::AdminMetadata do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with local call number/shelfmark (099)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '001' => 'in00000144356' },
            { '008' => '240703c20249999mnuuu         0    0eng d' },
            { '005' => '20250614160727.3' },
            { '040' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { 'a' => 'UCX' },
                { 'b' => 'eng' },
                { 'e' => 'rda' },
                { 'c' => 'UCX' },
                { 'd' => 'OCLCO' },
                { 'd' => 'RCJ' },
                { 'd' => 'UtOrBLW' }
              ]
            } }
          ]
        }
      end

      it 'returns adminMetadata' do
        expect(build).to include({
                                   contributor: [{
                                     type: 'organization',
                                     name: [{ code: 'UCX', source: { code: 'marcorg' } }]
                                   }],
                                   event: [{
                                     type: 'creation',
                                     date: [{ value: '240703', encoding: { code: 'marc' } }]
                                   }, {
                                     type: 'modification',
                                     date: [{ value: '20250614', encoding: { code: 'iso8601' } }]
                                   }],
                                   identifier: [{ value: 'in00000144356', type: 'FOLIO' }],
                                   note: [{ value: "Converted from MARC to Cocina #{Time.zone.today.iso8601}",
                                            type: 'record origin' }]
                                 })
      end
    end
  end
end
