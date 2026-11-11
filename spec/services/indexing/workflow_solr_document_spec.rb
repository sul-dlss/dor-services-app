# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::WorkflowSolrDocument do
  describe '#add_error_time' do
    let(:doc) { described_class.new }

    it 'keeps the most recent error time' do
      doc.add_error_time(Time.utc(2026, 11, 9, 10))
      doc.add_error_time(Time.utc(2026, 11, 3, 10))
      expect(doc.to_h['wf_error_latest_dtpsidv']).to eq '2026-11-09T10:00:00Z'
    end

    it 'omits the field when there are no errors' do
      expect(doc.to_h).not_to have_key('wf_error_latest_dtpsidv')
    end
  end

  describe '#merge!' do
    let(:combined) { described_class.new }
    let(:later) { described_class.new { |doc| doc.add_error_time(Time.utc(2026, 11, 9, 10)) } }
    let(:earlier) { described_class.new { |doc| doc.add_error_time(Time.utc(2026, 11, 3, 10)) } }
    let(:no_errors) { described_class.new }

    it 'keeps the most recent error time across documents' do
      combined.merge!(later)
      combined.merge!(earlier)
      combined.merge!(no_errors)
      expect(combined.to_h['wf_error_latest_dtpsidv']).to eq '2026-11-09T10:00:00Z'
    end
  end
end
