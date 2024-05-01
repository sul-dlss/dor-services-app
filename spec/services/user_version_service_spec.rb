# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersionService do
  let(:druid) { 'druid:xz456jk0987' }
  let(:cocina_object) { create(:ar_dro, external_identifier: druid).to_cocina_with_metadata }
  let(:event_factory) { class_double(EventFactory, create: true) }
  let(:repository_object_version) { build(:repository_object_version, repository_object:, **attrs) }
  let(:repository_object) { build(:repository_object, object_type:, external_identifier: druid) }
  let(:version) { 1 }
  let(:object_type) { 'dro' }
  let(:attrs) do
    {
      version: 1,
      version_description: 'My new version',
      closed_at: Time.current
    }
  end

  describe '.create' do
    subject(:create) { described_class.create(druid:, version: 1, event_factory:) }

    context 'when the repository object is closed' do
      before do
        allow(RepositoryObject).to receive(:find_by!).and_return(repository_object)
        allow(repository_object.versions).to receive(:find_by!).and_return(repository_object_version)
      end

      it 'creates a user version' do
        create
        expect(repository_object_version.user_versions.count).to eq 1
      end
    end
  end
end
