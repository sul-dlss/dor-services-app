# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTag do
  describe 'tag_label/druid uniqueness' do
    let!(:existing_tag) { create(:administrative_tag) }

    it 'prevents duplicate rows' do
      expect { described_class.create(druid: existing_tag.druid, tag_label: existing_tag.tag_label) }.to raise_error(
        ActiveRecord::RecordNotUnique,
        /Key \(druid, tag_label_id\)=\(#{existing_tag.druid}, #{existing_tag.tag_label.id}\) already exists/
      )
    end
  end
end
