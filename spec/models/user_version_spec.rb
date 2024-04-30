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
      version_description: 'My new version'
    }
  end

  describe 'validation' do
    subject(:user_verison) { build(:user_version, repository_object_version:) }

    context 'when the repository object version is closed' do
      before do
        allow(repository_object).to receive(:open?).and_return(false)
      end

      it { is_expected.to be_valid }
    end

    context 'when the repository object version is open' do
      it { is_expected.not_to be_valid }
    end
  end
end
