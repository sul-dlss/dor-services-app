# frozen_string_literal: true

require 'rails_helper'

# Top-level access section, not part of description.access
RSpec.describe 'Cocina --> DataCite mappings for DROAccess (H2 specific)' do
  let(:cocina_item_access) { Cocina::Models::DROAccess.new(cocina_access) }
  let(:rights_list_attributes) { Cocina::ToDatacite::DROAccess.rights_list_attributes(cocina_item_access) }

  describe 'License' do
    # Top-level access section, not part of description
    # User selects Creative Commons Public Domain 1.0 license
    let(:cocina_access) do
      {
        license: 'https://creativecommons.org/publicdomain/mark/1.0/'
      }
    end

    it 'populates rights_list_attributes correctly' do
      expect(rights_list_attributes).to eq(
        {
          rights: 'https://creativecommons.org/publicdomain/mark/1.0/'
        }
      )
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina DROAccess has empty hash' do
    let(:cocina_access) do
      {
      }
    end

    it 'rights_list_attributes is empty hash' do
      expect(rights_list_attributes).to eq({})
    end
  end
end
