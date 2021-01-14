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

  # 1. Classification with authority
  context 'when given a classification with authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": 'G9801.S12 2015 .Z3',
            "source": {
              "code": 'lcc'
            }
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <classification authority="lcc">G9801.S12 2015 .Z3</classification>
    XML
  end

  # missing example ticketed as https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/294
  context 'when given a classification without authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": 'G9801.S12 2015 .Z3'
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <classification>G9801.S12 2015 .Z3</classification>
    XML
  end

  # 2. Classification with edition
  context 'when given a classification with authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": '683',
            "source": {
              "code": 'ddc',
              "version": '11th edition'
            }
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <classification authority="ddc" edition="11">683</classification>
    XML
  end

  # 3. Display label
  context 'when given a classification with a display label' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": 'ML410.B3',
            "displayLabel": 'Library of Congress classification',
            "source": {
              "code": 'lcc'
            }
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <classification authority="lcc" displayLabel="Library of Congress classification">ML410.B3</classification>
    XML
  end

  # 4. Multiple classifications
  context 'when given multiple classifications' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": '683',
            "source": {
              "code": 'ddc',
              "version": '11th edition'
            }
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'classification',
            "value": '684',
            "source": {
              "code": 'ddc',
              "version": '12th edition'
            }
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <classification authority="ddc" edition="11">683</classification>
      <classification authority="ddc" edition="12">684</classification>
    XML
  end
end
