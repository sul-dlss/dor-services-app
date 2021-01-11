# frozen_string_literal: true

require 'rails_helper'

# numbered examples here from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_targetAudience.txt
RSpec.describe Cocina::FromFedora::Descriptive::Notes do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  # Example 1. Target audience with authority
  context 'with authority' do
    let(:xml) do
      <<~XML
        <targetAudience authority="marctarget">juvenile</targetAudience>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'juvenile',
          "type": 'target audience',
          "source": {
            "code": 'marctarget'
          }
        }
      ]
    end
  end

  # Example 2. Target audience without authority
  context 'without authority' do
    let(:xml) do
      <<~XML
        <targetAudience>ages 3-6</targetAudience>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'ages 3-6',
          "type": 'target audience'
        }
      ]
    end
  end
end
