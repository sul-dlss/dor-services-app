# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersion do
  let(:repository_object_version) { build(:repository_object_version, repository_object:, **attrs) }
  let(:repository_object) { build(:repository_object, object_type:, external_identifier: druid) }
  let(:druid) { 'druid:xz456jk0987' }
  let(:object_type) { 'dro' }

  let(:attrs) do
    {
      version_description: 'My new version',
      closed_at: Time.current
    }
  end

  describe 'validation' do
    subject(:errors) { user_version.errors.full_messages_for('repository_object_version') }

    let(:user_version) { build(:user_version, repository_object_version:) }

    before do
      user_version.validate
    end

    context 'when the user version is valid' do
      it { is_expected.to be_empty }
    end

    context 'when the repository object version is open' do
      let(:attrs) do
        {
          version_description: 'My new version'
        }
      end

      it {
        expect(errors)
          .to include 'Repository object version cannot set a user version to an open RepositoryObjectVersion'
      }
    end

    context 'when the repository object version is has no cocina' do
      let(:repository_object_version) { RepositoryObjectVersion.new(**attrs) }

      it {
        expect(errors)
          .to include 'Repository object version cannot set a user version to an RepositoryObjectVersion without cocina'
      }
    end

    context 'when the user version cannot be withdrawn' do
      let(:user_version) { build(:user_version, repository_object_version:, version: nil, state: 'withdrawn') }

      it { is_expected.to include 'Repository object version head version cannot be withdrawn' }
    end

    context 'when the user version is permanently withdrawn' do
      let(:user_version) do
        user_version = create(:user_version, repository_object_version:, state: 'permanently_withdrawn')
        user_version.state = 'available'
        user_version
      end

      it { is_expected.to include 'Repository object version cannot set user version state when permanently withdrawn' }
    end
  end

  describe '#as_json' do
    let(:user_version) { build(:user_version, repository_object_version:, state:) }

    context 'when the user version is withdrawn' do
      let(:state) { 'withdrawn' }

      it 'returns the user version as JSON' do
        expect(user_version.as_json).to eq(
          userVersion: user_version.version,
          version: user_version.repository_object_version.version,
          withdrawn: true,
          withdrawable: false,
          restorable: true,
          head: false
        )
      end
    end

    context 'when the user version is permanently withdrawn' do
      let(:state) { 'permanently_withdrawn' }

      it 'returns the user version as JSON' do
        expect(user_version.as_json).to eq(
          userVersion: user_version.version,
          version: user_version.repository_object_version.version,
          withdrawn: false,
          withdrawable: false,
          restorable: false,
          head: false
        )
      end
    end

    context 'when the user version is available' do
      let(:state) { 'available' }

      it 'returns the user version as JSON' do
        expect(user_version.as_json).to eq(
          userVersion: user_version.version,
          version: user_version.repository_object_version.version,
          withdrawn: false,
          withdrawable: true,
          restorable: false,
          head: false
        )
      end
    end
  end
end
