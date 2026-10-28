# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::EventsIndexer do
  subject(:doc) { described_class.new(last_event:).to_solr }

  let(:druid) { 'druid:bc123df4567' }

  context 'when there is no last event' do
    let(:last_event) { nil }

    it { is_expected.to eq({}) }
  end

  context 'when there is a last event with who' do
    let(:last_event) do
      create(:event, druid:, event_type: 'version_close', data: { who: 'jcoyne' },
                     created_at: Time.zone.parse('2026-10-01T12:00:00Z'))
      Event.last_updates_for(druids: [druid])[druid]
    end

    it 'indexes when and by whom' do
      expect(doc).to eq('last_updated_at_dtpsidv' => '2026-10-01T12:00:00Z', 'last_updated_by_ssidv' => 'jcoyne')
    end
  end

  context 'when there is a last event without who' do
    let(:last_event) do
      create(:event, druid:, event_type: 'registration', data: { who: nil },
                     created_at: Time.zone.parse('2026-10-01T12:00:00Z'))
      Event.last_updates_for(druids: [druid])[druid]
    end

    it 'indexes only when' do
      expect(doc).to eq('last_updated_at_dtpsidv' => '2026-10-01T12:00:00Z')
    end
  end
end
