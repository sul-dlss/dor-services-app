# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawRestoreJob do
  subject(:perform) do
    described_class.perform_now(user_version:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:user_version) { create(:user_version, state:, repository_object_version:) }
  let(:repository_object_version) do
    create(:repository_object_version, :with_repository_object, external_identifier: druid, closed_at: Time.current)
  end

  context 'when the version is withdrawn' do
    let(:state) { 'withdrawn' }

    before do
      allow(PurlFetcher::Client::Withdraw).to receive(:withdraw)
    end

    it 'withdraws the version' do
      perform
      expect(PurlFetcher::Client::Withdraw).to have_received(:withdraw).with(druid:, version: user_version.version)
    end
  end

  context 'when the version is not withdrawn' do
    let(:state) { 'available' }

    before do
      allow(PurlFetcher::Client::Withdraw).to receive(:restore)
    end

    it 'restores the version' do
      perform
      expect(PurlFetcher::Client::Withdraw).to have_received(:restore).with(druid:, version: user_version.version)
    end
  end
end
