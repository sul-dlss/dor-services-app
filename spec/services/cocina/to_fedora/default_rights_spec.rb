# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::DefaultRights do
  let(:item) do
    Dor::AdminPolicyObject.new
  end
  let(:default_object_rights_ds) { item.defaultObjectRights }

  describe 'write' do
    subject(:write) { described_class.write(default_object_rights_ds, default_access) }

    let(:license_nodes) { default_object_rights_ds.ng_xml.xpath('//use/license') }
    let(:license) { license_nodes.text }

    context 'when license is not present' do
      let(:default_access) do
        Cocina::Models::AdminPolicyDefaultAccess.new(
          access: 'world',
          download: 'world'
        )
      end

      it 'builds the xml' do
        write
        expect(license_nodes).to be_empty
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
        expect(license).to eq 'https://creativecommons.org/publicdomain/mark/1.0/'
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
        expect(license).to eq 'http://opendatacommons.org/licenses/pddl/1.0/'
      end
    end
  end
end
