# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundJobResult do
  describe '#output' do
    subject(:output) { background_job_result.output }

    context 'when output is a hash' do
      let(:background_job_result) { create(:background_job_result, output: { 'key' => 'value' }) }

      it 'allows indifferent key access' do
        expect(output[:key]).to eq('value')
        expect(output['key']).to eq('value')
      end
    end

    context 'when output is an array' do
      let(:background_job_result) { create(:background_job_result, output: [['druid:ab123cd4567', 'complete']]) }

      it 'returns an Array' do
        expect(output).to be_an(Array)
      end

      it 'returns the array unchanged' do
        expect(output).to eq([['druid:ab123cd4567', 'complete']])
      end
    end
  end
end
