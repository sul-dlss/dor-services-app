# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessMergeService do
  let(:merged_access) { described_class.merge(cocina_object, apo_object) }

  let(:apo_object) { instance_double(Cocina::Models::AdminPolicy, administrative: apo_administrative) }
  let(:apo_administrative) { instance_double(Cocina::Models::AdminPolicyAdministrative, defaultAccess: default_access) }

  context 'when a RequestDRO' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestDRO, access: access, collection?: false) }

    context 'when no access but APO has access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'location-based',
          download: 'none',
          readLocation: 'spec'
        )
      end

      it 'uses APO access' do
        expect(merged_access).to eq(Cocina::Models::DROAccess.new(
                                      access: 'location-based',
                                      download: 'none',
                                      readLocation: 'spec'
                                    ))
      end
    end

    context 'when no access and APO has no access' do
      let(:access) { nil }

      let(:default_access) { nil }

      it 'uses default access (dark)' do
        expect(merged_access).to eq(Cocina::Models::DROAccess.new)
      end
    end

    context 'when access already has rights' do
      let(:access) do
        Cocina::Models::DROAccess.new(
          access: 'stanford',
          download: 'none',
          controlledDigitalLending: true
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'location-based',
          download: 'none',
          readLocation: 'spec'
        )
      end

      it 'retains rights' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access has copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::DROAccess.new(
          access: 'world',
          download: 'world',
          copyright: 'dro copyright',
          useAndReproductionStatement: 'dro use and reproduction statement',
          license: 'https://www.gnu.org/licenses/agpl.txt'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'dark',
          download: 'none',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'retains' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access does not have copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::DROAccess.new(
          access: 'world',
          download: 'world'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'location-based',
          download: 'none',
          readLocation: 'spec',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'inherits' do
        expect(merged_access).to eq(Cocina::Models::DROAccess.new(
                                      access: 'world',
                                      download: 'world',
                                      copyright: 'apo copyright',
                                      useAndReproductionStatement: 'apo use and reproduction statement',
                                      license: 'https://www.apache.org/licenses/LICENSE-2.0'
                                    ))
      end
    end
  end

  context 'when a RequestCollection' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestCollection, access: access, collection?: true) }

    context 'when no access but APO has dark access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'dark',
          download: 'none',
          readLocation: 'spec'
        )
      end

      it 'uses APO access' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      access: 'dark'
                                    ))
      end
    end

    context 'when no access but APO has non-dark access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'stanford',
          download: 'none',
          readLocation: 'spec'
        )
      end

      it 'uses world access' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      access: 'world'
                                    ))
      end
    end

    context 'when no access and APO has no access' do
      let(:access) { nil }

      let(:default_access) { nil }

      it 'uses default access (dark)' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new)
      end
    end

    context 'when access already has rights' do
      let(:access) do
        Cocina::Models::CollectionAccess.new(
          access: 'world'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'dark'
        )
      end

      it 'retains rights' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access has copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::CollectionAccess.new(
          access: 'world',
          copyright: 'collection copyright',
          useAndReproductionStatement: 'collection use and reproduction statement',
          license: 'https://www.gnu.org/licenses/agpl.txt'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'location-based',
          download: 'none',
          readLocation: 'spec',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'retains' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access does not have copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::CollectionAccess.new(
          access: 'dark'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'location-based',
          download: 'none',
          readLocation: 'spec',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'inherits' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      access: 'dark',
                                      copyright: 'apo copyright',
                                      useAndReproductionStatement: 'apo use and reproduction statement',
                                      license: 'https://www.apache.org/licenses/LICENSE-2.0'
                                    ))
      end
    end
  end
end
