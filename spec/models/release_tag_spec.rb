# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTag do
  describe 'default_scope' do
    let!(:release_tag1) { create(:release_tag, created_at: Time.zone.now) }
    let!(:release_tag2) { create(:release_tag, created_at: 1.day.ago) }

    it 'orders by created_at' do
      expect(described_class.all).to eq([release_tag2, release_tag1])
    end
  end
end
