# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTag do
  describe 'tag/druid uniqueness validation' do
    let!(:existing_tag) { create(:administrative_tag) }
    let(:duplicate_tag) { described_class.create(druid: existing_tag.druid, tag_label: existing_tag.tag_label) }

    it 'prevents duplicate rows' do
      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors.full_messages).to include('Tag label has already been assigned to the given druid (no duplicate tags for a druid)')
    end
  end
end
