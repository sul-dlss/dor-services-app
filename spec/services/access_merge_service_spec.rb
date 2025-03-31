# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessMergeService do
  let(:merged_access) { described_class.merge(cocina_object, apo_object) }

  let(:apo_object) { instance_double(Cocina::Models::AdminPolicy, administrative: apo_administrative) }
  let(:apo_administrative) do
    instance_double(Cocina::Models::AdminPolicyAdministrative, accessTemplate: default_access)
  end

  context 'when a RequestDRO' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestDRO, access:, collection?: false) }

    context 'when no access but APO has access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'location-based',
          download: 'none',
          location: 'spec'
        )
      end

      it 'uses APO access' do
        expect(merged_access).to eq(Cocina::Models::DROAccess.new(
                                      view: 'location-based',
                                      download: 'none',
                                      location: 'spec'
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
          view: 'stanford',
          download: 'none',
          controlledDigitalLending: true
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'location-based',
          download: 'none',
          location: 'spec'
        )
      end

      it 'retains rights' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access has copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::DROAccess.new(
          view: 'world',
          download: 'world',
          copyright: 'dro copyright',
          useAndReproductionStatement: 'dro use and reproduction statement',
          license: 'https://www.gnu.org/licenses/agpl.txt'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'dark',
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
          view: 'world',
          download: 'world'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'location-based',
          download: 'none',
          location: 'spec',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'inherits' do
        expect(merged_access).to eq(Cocina::Models::DROAccess.new(
                                      view: 'world',
                                      download: 'world',
                                      copyright: 'apo copyright',
                                      useAndReproductionStatement: 'apo use and reproduction statement',
                                      license: 'https://www.apache.org/licenses/LICENSE-2.0'
                                    ))
      end
    end
  end

  context 'when a RequestCollection' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestCollection, access:, collection?: true) }

    context 'when no access but APO has dark access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'dark',
          download: 'none',
          location: 'spec'
        )
      end

      it 'uses APO access' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      view: 'dark'
                                    ))
      end
    end

    context 'when no access but APO has non-dark access' do
      let(:access) { nil }

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'stanford',
          download: 'none',
          location: 'spec'
        )
      end

      it 'uses world access' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      view: 'world'
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
          view: 'world'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'dark'
        )
      end

      it 'retains rights' do
        expect(merged_access).to eq(access)
      end
    end

    context 'when access has copyright, useAndReproductionStatement, license' do
      let(:access) do
        Cocina::Models::CollectionAccess.new(
          view: 'world',
          copyright: 'collection copyright',
          useAndReproductionStatement: 'collection use and reproduction statement',
          license: 'https://www.gnu.org/licenses/agpl.txt'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'location-based',
          download: 'none',
          location: 'spec',
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
          view: 'dark'
        )
      end

      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(
          view: 'location-based',
          download: 'none',
          location: 'spec',
          copyright: 'apo copyright',
          useAndReproductionStatement: 'apo use and reproduction statement',
          license: 'https://www.apache.org/licenses/LICENSE-2.0'
        )
      end

      it 'inherits' do
        expect(merged_access).to eq(Cocina::Models::CollectionAccess.new(
                                      view: 'dark',
                                      copyright: 'apo copyright',
                                      useAndReproductionStatement: 'apo use and reproduction statement',
                                      license: 'https://www.apache.org/licenses/LICENSE-2.0'
                                    ))
      end
    end
  end
end
