# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::EventDataFieldBuilder do
  describe '.build' do
    subject(:build) do
      described_class.build(
        field:,
        type:,
        role:,
        location_codes:,
        contributor_codes:,
        date_code:,
        strip_date_punctuation:
      )
    end

    let(:type) { 'publication' }
    let(:role) { 'publisher' }
    let(:location_codes) { ['a'] }
    let(:contributor_codes) { ['b'] }
    let(:date_code) { 'c' }
    let(:strip_date_punctuation) { true }
    let(:field) do
      MARC::DataField.new(
        '264',
        ' ',
        '1',
        ['a', 'Stanford, Calif. :'],
        ['b', 'Stanford University Press,'],
        ['c', '2019.']
      )
    end

    it 'builds a normalized event hash' do
      expect(build).to eq(
        type: 'publication',
        location: [{ value: 'Stanford, Calif.' }],
        contributor: [{ name: [{ value: 'Stanford University Press' }], role: [{ value: 'publisher' }] }],
        date: [{ value: '2019', type: 'publication' }]
      )
    end

    context 'when multiple mapped subfields are present' do
      let(:field) do
        MARC::DataField.new(
          '264',
          ' ',
          '1',
          ['a', 'Paris :'],
          ['a', 'London :'],
          ['b', 'Publisher one :'],
          ['b', 'Publisher two,'],
          ['c', '[after 1803]']
        )
      end

      it 'builds arrays for each mapped value' do
        expect(build).to eq(
          type: 'publication',
          location: [{ value: 'Paris' }, { value: 'London' }],
          contributor: [
            { name: [{ value: 'Publisher one' }], role: [{ value: 'publisher' }] },
            { name: [{ value: 'Publisher two' }], role: [{ value: 'publisher' }] }
          ],
          date: [{ value: '[after 1803]', type: 'publication' }]
        )
      end
    end

    context 'when no role is provided' do
      let(:role) { nil }

      it 'omits contributor roles' do
        expect(build).to eq(
          type: 'publication',
          location: [{ value: 'Stanford, Calif.' }],
          contributor: [{ name: [{ value: 'Stanford University Press' }] }],
          date: [{ value: '2019', type: 'publication' }]
        )
      end
    end

    context 'when date punctuation should be preserved' do
      let(:type) { 'manufacture' }
      let(:role) { 'manufacturer' }
      let(:location_codes) { ['e'] }
      let(:contributor_codes) { ['f'] }
      let(:date_code) { 'g' }
      let(:strip_date_punctuation) { false }
      let(:field) do
        MARC::DataField.new(
          '260',
          ' ',
          ' ',
          ['e', '(Twickenham :'],
          ['f', 'CTD Printers,'],
          ['g', '1974)']
        )
      end

      it 'keeps the original date value' do
        expect(build).to eq(
          type: 'manufacture',
          location: [{ value: '(Twickenham' }],
          contributor: [{ name: [{ value: 'CTD Printers' }], role: [{ value: 'manufacturer' }] }],
          date: [{ value: '1974)', type: 'manufacture' }]
        )
      end
    end

    context 'when only the type would be present' do
      let(:field) { MARC::DataField.new('264', ' ', '1') }

      it 'returns nil' do
        expect(build).to be_nil
      end
    end

    context 'when the date subfield contains only a period' do
      let(:field) do
        MARC::DataField.new(
          '264',
          ' ',
          '1',
          ['a', 'Stanford, Calif. :'],
          ['b', 'Stanford University Press,'],
          ['c', '.']
        )
      end

      it 'omits the date' do
        expect(build).to eq(
          type: 'publication',
          location: [{ value: 'Stanford, Calif.' }],
          contributor: [{ name: [{ value: 'Stanford University Press' }], role: [{ value: 'publisher' }] }]
        )
      end
    end

    context 'when the date subfield contains only a period and no other fields' do
      let(:field) do
        MARC::DataField.new(
          '260',
          ' ',
          ' ',
          ['c', '.']
        )
      end

      it 'returns nil' do
        expect(build).to be_nil
      end
    end
  end
end
