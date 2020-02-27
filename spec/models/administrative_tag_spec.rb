# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTag do
  describe 'tag format validation' do
    context 'with invalid values' do
      ['Configured With', 'Registered By:mjg'].each do |tag_string|
        subject(:tag) { described_class.new(tag: tag_string) }

        it { is_expected.not_to be_valid }
      end
    end

    context 'with valid values' do
      ['Registered By : mjgiarlo', 'Process : Content Type : Map'].each do |tag_string|
        subject(:tag) { described_class.new(tag: tag_string) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'tag/druid uniqueness validation' do
    let!(:existing_tag) { create(:administrative_tag) }
    let(:duplicate_tag) { described_class.create(druid: existing_tag.druid, tag: existing_tag.tag) }

    it 'prevents duplicate rows' do
      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors.full_messages).to include('Tag has already been assigned to the given druid (no duplicate tags for a druid)')
    end
  end
end
