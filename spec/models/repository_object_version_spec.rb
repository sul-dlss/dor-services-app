# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryObjectVersion do
  subject(:repository_object_version) do
    build(:repository_object_version, object_type_trait, :with_repository_object, external_identifier: druid, **attrs)
  end

  let(:druid) { 'druid:xz456jk0987' }
  let(:object_type_trait) { :dro_repository_object_version }
  let(:attrs) do
    {
      version: 1,
      version_description: 'My new version'
    }
  end

  describe 'validation' do
    it { is_expected.to be_valid }

    context 'without a version' do
      let(:attrs) do
        {
          version: nil,
          version_description: 'My new version'
        }
      end

      it { is_expected.not_to be_valid }
    end

    context 'without a version description' do
      let(:attrs) do
        {
          version: 2,
          version_description: nil
        }
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe 'with an updated sourceId' do
    let(:repository_object_version) { create(:repository_object_version, repository_object:, **attrs) }
    let(:repository_object) { create(:repository_object, **repo_object_attrs) }
    let(:repo_object_attrs) do
      {
        source_id: 'sul:old-source-id'
      }
    end
    let(:attrs) do
      {
        version: 2,
        version_description: 'My version 2',
        identification: {
          sourceId: 'sul:source-id'
        }
      }
    end
    let(:new_attrs) do
      {
        identification: {
          sourceId: 'sul:new-source-id'
        }
      }
    end

    context 'when version is opened and head version' do
      before do
        repository_object.update(opened_version: repository_object_version, head_version: repository_object_version)
      end

      it 'updates repository object' do
        repository_object_version.update(new_attrs)
        expect(repository_object.source_id).to eq('sul:new-source-id')
      end
    end

    context 'when version is not opened version' do
      before do
        allow(repository_object).to receive(:update)
      end

      it 'does not update repository object' do
        repository_object_version.update(new_attrs)
        expect(repository_object).not_to have_received(:update)
        expect(repository_object.source_id).to eq('sul:old-source-id')
      end
    end
  end

  describe '.to_cocina' do
    context 'with a DRO' do
      let(:attrs) do
        {
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          access: { view: 'world', download: 'world' },
          administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
          identification: { sourceId: 'sul:old-source-id' },
          description:
            {
              title: [{ value: 'RepositoryObjectVersion Test DRO' }],
              purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
            },
          structural: {},
          geographic: nil
        }
      end

      it 'returns a Cocina::Models::DRO from the RepositoryObjectVersion' do
        expect(repository_object_version.to_cocina).to be_a(Cocina::Models::DRO)
      end
    end

    context 'with a Collection' do
      let(:object_type) { 'collection' }
      let(:attrs) do
        {
          content_type: 'https://cocina.sul.stanford.edu/models/collection',
          access: { view: 'world' },
          administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
          identification: { sourceId: 'sul:old-source-id' },
          description:
            {
              title: [{ value: 'RepositoryObjectVersion Test Collection' }],
              purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
            },
          structural: nil,
          geographic: nil
        }
      end

      it 'returns a Cocina::Models::Collection from the RepositoryObjectVersion' do
        expect(repository_object_version.to_cocina).to be_a(Cocina::Models::Collection)
      end
    end

    context 'with an APO' do
      let(:object_type) { 'admin_policy' }
      let(:attrs) do
        {
          content_type: 'https://cocina.sul.stanford.edu/models/admin_policy',
          access: nil,
          administrative:
            {
              hasAdminPolicy: 'druid:hy787xj5878',
              hasAgreement: 'druid:bb033gt0615',
              accessTemplate: { view: 'world', download: 'world' }
            },
          identification: nil,
          description:
            {
              title: [{ value: 'RepositoryObjectVersion Test Collection' }],
              purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
            },
          structural: nil,
          geographic: nil
        }
      end

      it 'returns a Cocina::Models::AdminPolicy from the RepositoryObjectVersion' do
        expect(repository_object_version.to_cocina).to be_a(Cocina::Models::AdminPolicy)
      end
    end
  end

  describe '.to_cocina_with_metadata' do
    context 'with a DRO' do
      let(:attrs) do
        {
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          access: { view: 'world', download: 'world' },
          administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
          identification: { sourceId: 'sul:old-source-id' },
          description:
            {
              title: [{ value: 'RepositoryObjectVersion Test DRO' }],
              purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
            },
          structural: {},
          geographic: nil
        }
      end

      it 'returns a Cocina::Models::DRO from the RepositoryObjectVersion' do
        expect(repository_object_version.to_cocina_with_metadata).to be_a(Cocina::Models::DROWithMetadata)
      end
    end
  end

  describe '.to_model_hash' do
    subject(:model_hash) { described_class.to_model_hash(cocina_instance) }

    # Will test that updated to latest cocina version
    let(:cocina_instance) do
      build(cocina_object_type).new(cocinaVersion: '0.5.0')
    end

    context 'with a DRO' do
      let(:cocina_object_type) { :dro }

      it { is_expected.to be_a(Hash) }
      it { is_expected.not_to include(:externalIdentifier) }
      it { is_expected.not_to include(:version) }
      it { is_expected.to include(cocina_version: Cocina::Models::VERSION) }
      it { is_expected.to include(content_type: Cocina::Models::ObjectType.object) }
      it { is_expected.to include(geographic: nil) }

      context 'with geographic metadata' do
        let(:cocina_instance) do
          build(:dro).new(geographic: { iso19139: 'some gross XML string' })
        end

        it { is_expected.to include(geographic: { iso19139: 'some gross XML string' }) }
      end
    end

    context 'with a collection' do
      let(:cocina_object_type) { :collection }

      it { is_expected.to be_a(Hash) }
      it { is_expected.not_to include(:externalIdentifier) }
      it { is_expected.not_to include(:version) }
      it { is_expected.to include(cocina_version: Cocina::Models::VERSION) }
      it { is_expected.to include(content_type: Cocina::Models::ObjectType.collection) }
    end

    context 'with an admin policy' do
      let(:cocina_object_type) { :admin_policy }

      it { is_expected.to be_a(Hash) }
      it { is_expected.not_to include(:externalIdentifier) }
      it { is_expected.not_to include(:version) }
      it { is_expected.to include(cocina_version: Cocina::Models::VERSION) }
      it { is_expected.to include(content_type: Cocina::Models::ObjectType.admin_policy) }
      it { is_expected.to include(description: hash_including(:title)) }

      context 'with no description' do
        let(:cocina_instance) do
          # NOTE: The cocina-models factories (as of v0.96.0) don't seem to
          #       provide a better way to build an APO sans description.
          Cocina::Models::AdminPolicy.new(build(:admin_policy).to_h.except(:description))
        end

        it { is_expected.to include(description: nil) }
      end
    end
  end

  describe '.closed?' do
    context 'when closed_at is nil' do
      it 'returns false' do
        expect(repository_object_version.closed?).to be false
      end
    end

    context 'when closed_at is present' do
      let(:attrs) do
        {
          version: 1,
          version_description: 'My new version',
          closed_at: Time.current
        }
      end

      it 'returns true when closed_at is present' do
        expect(repository_object_version.closed?).to be true
      end
    end
  end

  describe '.open?' do
    context 'when closed_at is nil' do
      it 'returns true when closed_at is nil' do
        expect(repository_object_version.open?).to be true
      end
    end

    context 'when closed_at is present' do
      let(:attrs) do
        {
          version: 1,
          version_description: 'My new version',
          closed_at: Time.current
        }
      end

      it 'returns false when closed_at is present' do
        expect(repository_object_version.open?).to be false
      end
    end
  end
end
