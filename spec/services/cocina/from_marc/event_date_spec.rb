# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::EventDate do
  describe '.build' do
    subject(:build) do
      described_class.build(record_type:, field: MARC::ControlField.new('008', field_value))
    end

    let(:record_type) { 'publication' }
    let(:date_code) { 's' }
    let(:initial_date) { '2019' }
    let(:terminal_date) { '    ' }
    let(:field_value) { "000000#{date_code}#{initial_date}#{terminal_date}" }

    context 'when 008/06 indicates multiple dates but terminal date is blank' do
      let(:date_code) { 'm' }
      let(:initial_date) { '1844' }

      it 'returns a single encoded date' do
        expect(build).to eq([
                              { value: '1844', type: 'publication', encoding: { code: 'marc' } }
                            ])
      end
    end

    context 'when 008/06 indicates multiple dates and both dates are present' do
      let(:date_code) { 'm' }
      let(:initial_date) { '2017' }
      let(:terminal_date) { '2018' }

      it 'returns both encoded dates' do
        expect(build).to eq([
                              { value: '2017', type: 'publication', encoding: { code: 'marc' } },
                              { value: '2018', type: 'publication', encoding: { code: 'marc' } }
                            ])
      end
    end

    context 'when the date range is open ended' do
      let(:date_code) { 'c' }
      let(:initial_date) { '2017' }
      let(:terminal_date) { '9999' }

      it 'returns a structured date with only a start value' do
        expect(build).to eq([
                              {
                                structuredValue: [
                                  { value: '2017', type: 'start' }
                                ],
                                type: 'publication',
                                encoding: { code: 'marc' }
                              }
                            ])
      end
    end

    context 'when the date range has an unknown end' do
      let(:date_code) { 'c' }
      let(:initial_date) { '2017' }
      let(:terminal_date) { 'uuuu' }

      it 'returns a structured date with only a start value' do
        expect(build).to eq([
                              {
                                structuredValue: [
                                  { value: '2017', type: 'start' }
                                ],
                                type: 'publication',
                                encoding: { code: 'marc' }
                              }
                            ])
      end
    end

    context 'when the date code is uncoded and the initial date is present' do
      let(:date_code) { ' ' }
      let(:initial_date) { '2024' }

      it 'treats the value as a single encoded date' do
        expect(build).to eq([
                              { value: '2024', type: 'publication', encoding: { code: 'marc' } }
                            ])
      end
    end

    context 'when a structured range is missing its initial date' do
      let(:date_code) { 'q' }
      let(:initial_date) { '||||' }
      let(:terminal_date) { '1965' }

      it 'returns nothing' do
        expect(build).to be_nil
      end
    end

    context 'when the initial date is not a valid MARC date' do
      let(:initial_date) { '201x' }

      it 'returns nothing' do
        expect(build).to be_nil
      end
    end

    context 'when the terminal date is not a valid MARC date' do
      let(:date_code) { 'm' }
      let(:initial_date) { '2017' }
      let(:terminal_date) { '201x' }

      it 'returns nothing' do
        expect(build).to be_nil
      end
    end
  end
end
