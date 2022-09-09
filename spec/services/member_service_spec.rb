# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberService do
  let(:druid) { 'druid:bc123df4567' }

  before do
    allow(SolrService).to receive(:query)
  end

  describe '.for' do
    it 'queries for members' do
      described_class.for(druid)
      expect(SolrService).to have_received(:query)
        .with(/#{druid}/, anything)
        .once
    end

    context 'with only_published param' do
      it 'queries for published members only' do
        described_class.for(druid, only_published: true)
        expect(SolrService).to have_received(:query)
          .with(/#{druid}.+published_dttsim:/, anything)
          .once
      end
    end

    context 'with exclude_opened param' do
      it 'queries for non-opened members only' do
        described_class.for(druid, exclude_opened: true)
        expect(SolrService).to have_received(:query)
          .with(/#{druid}.+processing_status_text_ssi:Opened/, anything)
          .once
      end
    end
  end
end
