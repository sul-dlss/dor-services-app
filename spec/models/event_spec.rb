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
end
