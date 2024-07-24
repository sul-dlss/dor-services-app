# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersion do
  let(:repository_object_version) { build(:repository_object_version, repository_object:, **attrs) }
  let(:repository_object) { build(:repository_object, object_type:, external_identifier: druid) }
  let(:druid) { 'druid:xz456jk0987' }
  let(:object_type) { 'dro' }

  let(:attrs) do
    {
      version: 1,
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
          version: 1,
          version_description: 'My new version'
        }
      end

      it { is_expected.to include 'Repository object version cannot set a user version to an open RepositoryObjectVersion' }
    end

    context 'when the repository object version is has no cocina' do
      let(:repository_object_version) { RepositoryObjectVersion.new(**attrs) }

      it { is_expected.to include 'Repository object version cannot set a user version to an RepositoryObjectVersion without cocina' }
    end

    context 'when the user version cannot be withdrawn' do
      let(:user_version) { build(:user_version, repository_object_version:, version: nil, withdrawn: true) }

      it { is_expected.to include 'Repository object version head version cannot be withdrawn' }
    end
  end
end
