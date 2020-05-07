# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagLabel, type: :model do
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
end
