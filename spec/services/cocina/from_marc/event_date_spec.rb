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

    context 'when a single date' do
      context 'when the initial date is present' do
        it 'returns a single encoded date' do
          expect(build).to eq([
                                { value: '2019', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when the initial date is not a valid MARC date' do
        let(:initial_date) { '201x' }

        it 'returns nothing' do
          expect(build).to be_nil
        end
      end
    end

    context 'when multiple dates' do
      let(:date_code) { 'm' }

      context 'when both dates are present' do
        let(:initial_date) { '2017' }
        let(:terminal_date) { '2018' }

        it 'returns both encoded dates' do
          expect(build).to eq([
                                { value: '2017', type: 'publication', encoding: { code: 'marc' } },
                                { value: '2018', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when the initial date is blank' do
        let(:initial_date) { '    ' }
        let(:terminal_date) { '2018' }

        it 'returns a single encoded date' do
          expect(build).to eq([
                                { value: '2018', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when terminal date is blank' do
        let(:initial_date) { '1844' }

        it 'returns a single encoded date' do
          expect(build).to eq([
                                { value: '1844', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when the terminal date is not a valid MARC date' do
        let(:initial_date) { '2017' }
        let(:terminal_date) { '????' }

        it 'treats the value as a single encoded date' do
          expect(build).to eq([
                                { value: '2017', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when the initial date is not a valid MARC date' do
        let(:initial_date) { '????' }
        let(:terminal_date) { '2017' }

        it 'treats the value as a single encoded date' do
          expect(build).to eq([
                                { value: '2017', type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when both dates are not valid MARC dates' do
        let(:initial_date) { '????' }
        let(:terminal_date) { '????' }

        it 'returns nil' do
          expect(build).to be_nil
        end
      end
    end

    context 'when a date range' do
      let(:date_code) { 'c' }

      context 'when open ended' do
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

      context 'when missing its initial date' do
        let(:date_code) { 'q' }
        let(:initial_date) { '||||' }
        let(:terminal_date) { '1965' }

        it 'returns nothing' do
          expect(build).to be_nil
        end
      end

      context 'when an unknown end' do
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

      context 'when the terminal date is not a valid MARC date' do
        let(:date_code) { 'd' }
        let(:initial_date) { '2017' }
        let(:terminal_date) { '01xx' }

        it 'treats the value as a single encoded date' do
          expect(build).to eq([
                                { structuredValue: [{ value: '2017', type: 'start' }], type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when the initial date is not a valid MARC date' do
        let(:initial_date) { '01xx' }
        let(:terminal_date) { '2017' }

        it 'treats the value as a single encoded date' do
          expect(build).to eq([
                                { structuredValue: [{ value: '2017', type: 'end' }], type: 'publication', encoding: { code: 'marc' } }
                              ])
        end
      end

      context 'when both dates are not a valid MARC date' do
        let(:date_code) { 'd' }
        let(:initial_date) { '01xx' }
        let(:terminal_date) { '02xx' }

        it 'returns nil' do
          expect(build).to be_nil
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
    end
  end
end
