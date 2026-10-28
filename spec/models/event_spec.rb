# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event do
  describe 'validation' do
    subject(:event) { build(:event, event_type:) }

    context 'with a known event type' do
      let(:event_type) { 'version_close' }

      it { is_expected.to be_valid }
    end

    context 'with a deprecated event type' do
      let(:event_type) { 'legacy_metadata_update' }

      it { is_expected.to be_valid }
    end

    context 'with an unknown event type' do
      let(:event_type) { 'important_action_completed' }

      it 'is invalid' do
        expect(event).not_to be_valid
        expect(event.errors[:event_type]).to eq ['is not included in the list']
      end
    end
  end

  describe '.last_updates_for' do
    subject(:last_updates) { described_class.last_updates_for(druids: [druid, other_druid, 'druid:mm111mm1111']) }

    let(:druid) { 'druid:bc123df4567' }
    let(:other_druid) { 'druid:bc123df4568' }

    before do
      create(:event, druid:, event_type: 'registration', data: { who: 'reg_user' }, created_at: 3.days.ago)
      create(:event, druid:, event_type: 'update', data: { who: 'update_user', success: false },
                     created_at: 2.days.ago)
      create(:event, druid:, event_type: 'publishing_complete', data: { who: 'ignored_user' }, created_at: 1.day.ago)
      create(:event, druid: other_druid, event_type: 'version_open', data: { who: 'open_user' }, created_at: 2.days.ago)
      create(:event, druid: other_druid, event_type: 'version_close', data: {}, created_at: 1.day.ago)
    end

    it 'returns the most recent update event for each druid' do
      expect(last_updates.keys).to contain_exactly(druid, other_druid)
      expect(last_updates[druid].who).to eq 'update_user'
      expect(last_updates[druid].created_at).to be_within(1.second).of(2.days.ago)
      expect(last_updates[other_druid].who).to be_nil
      expect(last_updates[other_druid].created_at).to be_within(1.second).of(1.day.ago)
    end
  end
end
