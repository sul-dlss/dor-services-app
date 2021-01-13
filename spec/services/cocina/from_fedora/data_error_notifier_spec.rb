# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::DataErrorNotifier do
  subject(:notifier) do
    described_class.new(druid: 'druid:zq087nd5094')
  end

  context 'when enabled' do
    before do
      allow(Honeybadger).to receive(:notify)
      allow(Settings.from_fedora_data_errors).to receive(:notify_warn).and_return(true)
      allow(Settings.from_fedora_data_errors).to receive(:notify_error).and_return(true)
    end

    it 'Honeybadger notifies for warning' do
      notifier.warn('Danger, Will Robinson!', { type: 'robot' })
      expect(Honeybadger).to have_received(:notify).with('[DATA WARNING] Danger, Will Robinson!', { context: { druid: 'druid:zq087nd5094', type: 'robot' }, tags: 'data_warning' })
    end

    it 'Honeybadger notifies for error' do
      notifier.error('Fix it! Fix it! Fix it!', { type: 'robot' })
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Fix it! Fix it! Fix it!', { context: { druid: 'druid:zq087nd5094', type: 'robot' }, tags: 'data_error' })
    end
  end

  context 'when disabled' do
    before do
      allow(Honeybadger).to receive(:notify)
      allow(Settings.from_fedora_data_errors).to receive(:notify_warn).and_return(false)
      allow(Settings.from_fedora_data_errors).to receive(:notify_error).and_return(false)
    end

    it 'No notification for warning' do
      notifier.warn('Danger, Will Robinson!', { type: 'robot' })
      expect(Honeybadger).not_to have_received(:notify)
    end

    it 'No notification for error' do
      notifier.error('Fix it! Fix it! Fix it!', { type: 'robot' })
      expect(Honeybadger).not_to have_received(:notify)
    end
  end
end
