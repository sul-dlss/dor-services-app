# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::DataErrorNotifier do
  subject(:notifier) do
    described_class.new(druid: 'druid:zq087nd5094')
  end

  describe '#error' do
    subject(:notifiy_error) { notifier.error('Fix it! Fix it! Fix it!', { type: 'robot' }) }

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'Honeybadger notifies for error' do
      notifiy_error
      expect(Honeybadger).to have_received(:notify)
        .with('[DATA ERROR] Fix it! Fix it! Fix it!',
              { context: { druid: 'druid:zq087nd5094', type: 'robot' },
                tags: 'data_error' })
    end
  end
end
