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
end
