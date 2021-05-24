# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpublishService do
  describe '#unpublish' do
    context 'with an object' do
      let(:druid) { 'druid:ab123cd4567' }

      before do
        allow(Settings).to receive(:purl_services_url).and_return('http://example.com/purl')

        stub_request(:delete, 'example.com/purl/purls/ab123cd4567')
      end

      it 'removes from purl' do
        described_class.unpublish(druid: druid)
        expect(WebMock).to have_requested(:delete, 'example.com/purl/purls/ab123cd4567')
      end
    end
  end
end
