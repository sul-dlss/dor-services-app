# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, subjects: subjects)
      end
    end
  end

  context 'when classification is nil' do
    let(:subjects) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification authority="lcc">G9801.S12 2015 .Z3</classification>
        </mods>
      XML
    end
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification authority="ddc" edition="11">683</classification>
        </mods>
      XML
    end
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification authority="lcc" displayLabel="Library of Congress classification">ML410.B3</classification>
        </mods>
      XML
    end
  end

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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification>G9801.S12 2015 .Z3</classification>
        </mods>
      XML
    end
  end
end
