# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersionService do
  let(:druid) { repository_object.external_identifier }
  let(:repository_object) { repository_object_version1.repository_object }
  let(:repository_object_version1) do
    create(:repository_object_version, :with_repository_object, closed_at: Time.zone.now, version: 1)
  end
  let!(:repository_object_version2) do
    create(:repository_object_version, version: 2, repository_object:, closed_at: Time.zone.now)
  end
  let(:object_type) { 'dro' }

  before do
    allow(EventFactory).to receive(:create)
    allow(PublishJob).to receive(:perform_later)
  end

  describe '.create' do
    subject(:user_version_service_create) { described_class.create(druid:, version: 1) }

    context 'when the repository object version is closed' do
      it 'creates a user version' do
        user_version_service_create
        expect(repository_object.user_versions.count).to eq 1
      end
    end

    context 'when the repository object version is open' do
      before do
        repository_object_version1.update(closed_at: nil)
      end

      it 'does not create a user version' do
        expect { user_version_service_create }.to raise_error UserVersionService::UserVersioningError
        expect(repository_object.user_versions.count).to eq 0
      end
    end

    context 'when the repository object is not found' do
      let(:druid) { 'druid:abc123def456' }

      it 'does not create a user version' do
        expect { user_version_service_create }.to raise_error UserVersionService::UserVersioningError
        expect(repository_object.user_versions.count).to eq 0
      end
    end
  end

  describe '.withdraw' do
    subject(:user_version_service_withdraw) { described_class.withdraw(druid:, user_version: 1) }

    let!(:user_version) { UserVersion.create!(version: 1, repository_object_version: repository_object_version1) }

    before do
      allow(WithdrawRestoreJob).to receive(:perform_later)
    end

    context 'when the user version can be withdrawn' do
      before do
        UserVersion.create!(version: 2, repository_object_version: repository_object_version2)
      end

      it 'withdraws the user version' do
        expect(user_version.withdrawn?).to be false
        user_version_service_withdraw
        expect(user_version.reload.withdrawn?).to be true
        expect(WithdrawRestoreJob).to have_received(:perform_later).with(user_version:)
      end
    end

    context 'when the user version cannot be withdrawn' do
      it 'raises' do
        expect(user_version.withdrawn?).to be false
        expect do
          user_version_service_withdraw
        end.to raise_error UserVersionService::UserVersioningError,
                           'Validation failed: Repository object version head version cannot be withdrawn'
        expect(WithdrawRestoreJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '.move' do
    subject(:user_version_service_move) { described_class.move(druid:, version: 2, user_version: 1) }

    let!(:user_version) { UserVersion.create!(version: 1, repository_object_version: repository_object_version1) }

    it 'moves the user version' do
      expect(user_version.repository_object_version).to eq repository_object_version1
      user_version_service_move
      expect(user_version.reload.repository_object_version).to eq repository_object_version2
      expect(PublishJob).to have_received(:perform_later).with(druid:, user_version: 1,
                                                               background_job_result: BackgroundJobResult)
    end
  end

  describe '.exist?' do
    subject(:user_version_service_exist?) { described_class.exist?(druid:, user_version: 1) }

    let!(:user_version) { UserVersion.create!(version: 1, repository_object_version: repository_object_version1) }

    it 'returns true if the user version exists' do
      expect(user_version_service_exist?).to be true
    end

    it 'returns false if the user version does not exist' do
      user_version.destroy
      expect(user_version_service_exist?).to be false
    end
  end

  describe '.permanently_withdraw_previous_user_versions' do
    subject(:user_version_service_permanently_withdraw) do
      described_class.permanently_withdraw_previous_user_versions(druid:)
    end

    let!(:user_version1) do
      UserVersion.create!(version: 1, repository_object_version: repository_object_version1,
                          state: 'permanently_withdrawn')
    end
    let!(:user_version2) { UserVersion.create!(version: 2, repository_object_version: repository_object_version1) }
    let!(:user_version3) { UserVersion.create!(version: 3, repository_object_version: repository_object_version1) }

    it 'permanently withdraws the previous user versions' do
      user_version_service_permanently_withdraw
      expect(user_version1.reload.permanently_withdrawn?).to be true
      expect(user_version2.reload.permanently_withdrawn?).to be true
      expect(user_version3.reload.available?).to be true

      expect(EventFactory).to have_received(:create).once
    end
  end
end
