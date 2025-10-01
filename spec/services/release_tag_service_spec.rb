# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTagService do
  let(:druid) { 'druid:bb004bn8654' }

  describe '.create' do
    subject(:create_tag) { described_class.create(druid:, tag:) }

    let(:tag) { Dor::ReleaseTag.new(to: 'Earthworks', what: 'self', who: 'cathy', date: 2.days.ago.iso8601) }

    it 'adds another release tag and' do
      expect { create_tag }.to change { ReleaseTag.where(druid:).count }.by(1)
    end
  end

  describe '.tags' do
    subject(:releases) { described_class.tags(druid:) }

    let!(:release_tag) { create(:release_tag, druid:) }

    it 'returns release tags from the ReleaseTag objects' do
      expect(releases).to eq [
        release_tag.to_cocina
      ]
    end
  end
end
