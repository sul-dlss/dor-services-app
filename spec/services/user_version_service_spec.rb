# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersionService do
  let(:druid) { 'druid:xz456jk0987' }
  let(:event_factory) { class_double(EventFactory, create: true) }
  let(:repository_object_version) { repository_object.versions.first }
  let(:repository_object) { create(:repository_object, object_type:, external_identifier: druid) }
  let(:object_type) { 'dro' }

  describe '.create' do
    subject(:user_version_service_create) { described_class.create(druid:, version: 1, event_factory:) }

    context 'when the repository object version is closed' do
      before do
        repository_object_version.update(closed_at: Time.current)
      end

      it 'creates a user version' do
        user_version_service_create
        expect(repository_object_version.user_versions.count).to eq 1
      end
    end

    context 'when the repository object version is open' do
      before do
        repository_object_version.update(closed_at: nil)
      end

      it 'does not create a user version' do
        expect { user_version_service_create }.to raise_error UserVersionService::UserVersioningError
        expect(repository_object_version.user_versions.count).to eq 0
      end
    end

    context 'when the repository object is not found' do
      it 'does not create a user version' do
        expect { user_version_service_create }.to raise_error UserVersionService::UserVersioningError
        expect(repository_object_version.user_versions.count).to eq 0
      end
    end
  end

  describe '.withdraw' do
    subject(:user_version_service_withdraw) { described_class.withdraw(user_version:, event_factory:) }

    let(:user_version) { UserVersion.create!(version: 1, repository_object_version:) }

    before do
      repository_object_version.update(closed_at: Time.current)
    end

    it 'withdraws the user version' do
      expect(user_version.reload.withdrawn).to be false
      user_version_service_withdraw
      expect(user_version.reload.withdrawn).to be true
    end
  end

  describe '.move' do
    subject(:user_version_service_move) { described_class.move(druid:, version: 2, user_version:, event_factory:) }

    let(:repository_object_version2) { RepositoryObjectVersion.create!(version: 2, version_description: 'My second version', repository_object:) }
    let(:user_version) { UserVersion.create!(version: 1, repository_object_version:) }

    before do
      repository_object_version.update(closed_at: Time.current)
      repository_object_version2.update(closed_at: Time.current)
    end

    it 'moves the user version' do
      expect(user_version.repository_object_version).to eq repository_object_version
      user_version_service_move
      expect(user_version.repository_object_version).to eq repository_object_version2
    end
  end

  describe '.exist?' do
    subject(:user_version_service_exist?) { described_class.exist?(druid:, user_version:) }

    let(:user_version) { UserVersion.create!(version: 1, repository_object_version:) }

    before do
      repository_object_version.update(closed_at: Time.current)
    end

    it 'returns true if the user version exists' do
      expect(user_version_service_exist?).to be true
    end

    it 'returns false if the user version does not exist' do
      user_version.destroy
      expect(user_version_service_exist?).to be false
    end
  end
end
