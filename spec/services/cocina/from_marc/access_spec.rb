# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Access do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with local call number/shelfmark (099)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '099' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [{ 'a' => 'MSS CODEX 1556 F' }]
            } }
          ]
        }
      end

      it 'returns physicalLocation with shelf locator' do
        expect(build).to eq({ physicalLocation: [{ value: 'MSS CODEX 1556 F', type: 'shelf locator' }] })
      end
    end

    context 'with url (856 $uyz3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '856' => {
              'ind1' => '4', 'ind2' => '0',
              'subfields' => [{ '3' => 'Current issue' }, { 'u' => 'https://purl.fdlp.gov/GPO/gpo121603' }]
            } }
          ]
        }
      end

      it 'returns a url' do
        expect(build).to eq({ url: [{ value: 'https://purl.fdlp.gov/GPO/gpo121603', displayLabel: 'Current issue' }] })
      end
    end

    context 'with url (856 $uyz3) that has a note' do
      let(:marc_hash) do
        {
          'fields' => [
            { '856' => {
              'ind1' => '4', 'ind2' => '0',
              'subfields' => [
                { 'z' => 'Available to Stanford-affiliated users.' },
                { 'u' => 'https://doi.org/10.1017/9781009675338' },
                { 'x' => 'WMS' },
                { 'y' => 'Cambridge University Press' }
              ]
            } }
          ]
        }
      end

      it 'returns a url and notes' do
        expect(build).to eq({
                              url: [
                                {
                                  value: 'https://doi.org/10.1017/9781009675338',
                                  note: [{ value: 'Available to Stanford-affiliated users.' },
                                         { value: 'Cambridge University Press' }]
                                }
                              ]
                            })
      end
    end
  end
end
