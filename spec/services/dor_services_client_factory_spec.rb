# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DorServicesClientFactory do
  describe '.build' do
    before do
      allow(Dor::Services::Client).to receive(:configure)
    end

    it 'configures Dor::Services::Client with the correct settings' do
      described_class.build
      expect(Dor::Services::Client).to have_received(:configure).with(
        url: Settings.dor_services.url,
        token: Settings.dor_services.token,
        enable_get_retries: true
      )
    end
  end
end
