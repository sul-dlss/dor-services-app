# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryObjectVersion do
  subject(:repository_object_version) do
    build(:repository_object_version, repository_object: build(:repository_object), **attrs)
  end

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

  describe '.in_virtual_objects' do
    before do
      opened_version.update(attrs)
    end

    let(:druid) { 'druid:xz456jk0987' }
    let(:opened_version) { create(:repository_object).opened_version }

    it 'returns an empty list' do
      expect(described_class.in_virtual_objects(druid)).to eq([])
    end

    context 'when object version has a relevant member order' do
      let(:attrs) do
        {
          structural: {
            hasMemberOrders: [
              {
                members: [
                  druid
                ]
              }
            ]
          }
        }
      end

      it 'returns the expected object version' do
        expect(described_class.in_virtual_objects(druid)).to eq([opened_version])
      end
    end
  end

  describe '.members_of_collection' do
    before do
      opened_version.update(attrs)
    end

    let(:druid) { 'druid:xz456jk0987' }
    let(:opened_version) { create(:repository_object).opened_version }

    it 'returns an empty list' do
      expect(described_class.members_of_collection(druid)).to eq([])
    end

    context 'when object version has a relevant member order' do
      let(:attrs) do
        {
          structural: {
            isMemberOf: druid
          }
        }
      end

      it 'returns the expected object version' do
        expect(described_class.members_of_collection(druid)).to eq([opened_version])
      end
    end
  end

  describe '.to_model_hash' do
    subject(:model_hash) { described_class.to_model_hash(cocina_instance) }

    let(:cocina_instance) { build(cocina_object_type) }

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
      it { is_expected.not_to include(:content_type) }
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
end
