# frozen_string_literal: true

require 'rails_helper'
require 'support/mods_mapping_spec_helper'

# numbered examples refer to https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_targetAudience.txt
RSpec.describe Cocina::ToFedora::Descriptive::Note do
  # see spec/support/mods_mapping_spec_helper.rb for how writer is used in shared examples
  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods(mods_attributes) do
        described_class.write(xml: xml, notes: notes, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  # 1. Target audience with authority
  context 'with authority' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'juvenile',
          "type": 'target audience',
          "source": {
            "code": 'marctarget'
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <targetAudience authority="marctarget">juvenile</targetAudience>
    XML
  end

  # 2. Target audience without authority
  context 'without authority' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'ages 3-6',
          "type": 'target audience'
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <targetAudience>ages 3-6</targetAudience>
    XML
  end
end
