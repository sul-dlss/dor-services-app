# frozen_string_literal: true

require 'rails_helper'

# numbered examples here from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_targetAudience.txt
RSpec.describe Cocina::ToFedora::Descriptive::Note do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, notes: notes, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  # Example 1. Target audience with authority
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <targetAudience authority="marctarget">juvenile</targetAudience>
        </mods>
      XML
    end
  end

  # Example 2. Target audience without authority
  context 'without authority' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'ages 3-6',
          "type": 'target audience'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <targetAudience>ages 3-6</targetAudience>
        </mods>
      XML
    end
  end
end
