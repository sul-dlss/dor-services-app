# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTag do
  describe '#from_cocina' do
    subject(:release_tag) { described_class.from_cocina(druid:, tag:) }

    let(:druid) { 'druid:bb004bn8654' }
    let(:date) { 2.days.ago.round }
    let(:tag) { Dor::ReleaseTag.new(to: 'Earthworks', what: 'self', who: 'cathy', date: date.iso8601) }

    it 'builds a release tag' do
      expect(release_tag.created_at).to eq date
      expect(release_tag.released_to).to eq 'Earthworks'
      expect(release_tag.what).to eq 'self'
    end
  end
end
