# frozen_string_literal: true

require 'rails_helper'
require 'support/mods_mapping_spec_helper'

# numbered examples refer to https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_classification.txt
RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  # see spec/support/mods_mapping_spec_helper.rb for how writer is used in shared examples
  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods(mods_attributes) do
        described_class.write(xml: xml, subjects: subjects, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when nil' do
    let(:subjects) { nil }

    it_behaves_like 'cocina to MODS', '' # empty MODS
  end
end
