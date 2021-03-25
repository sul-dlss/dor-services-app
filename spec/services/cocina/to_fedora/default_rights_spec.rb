# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::DefaultRights do
  let(:item) do
    Dor::AdminPolicyObject.new
  end
  let(:default_object_rights_ds) { item.defaultObjectRights }

  describe 'write' do
    subject(:write) { described_class.write(default_object_rights_ds, default_access) }

    context 'when license is not present' do
      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'world',
          download: 'world'
        )
      end

      it 'builds the xml' do
        write
        expect(default_object_rights_ds.use_license).to be_nil
      end
    end

    context 'when license is public domain' do
      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'world',
          download: 'world',
          license: 'https://creativecommons.org/publicdomain/mark/1.0/'
        )
      end

      it 'builds the xml' do
        write
        expect(default_object_rights_ds.use_license).to eq 'pdm'
      end
    end

    context 'when license is an open data license' do
      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'world',
          download: 'world',
          license: 'http://opendatacommons.org/licenses/pddl/1.0/'
        )
      end

      it 'builds the xml' do
        write
        expect(default_object_rights_ds.use_license).to eq 'pddl'
      end
    end
  end
end
